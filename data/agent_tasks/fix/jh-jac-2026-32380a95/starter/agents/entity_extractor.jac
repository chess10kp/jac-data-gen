# agents/entity_extractor.jac

import from byllm.llm { Model }
import from nodes.data_nodes {
    DocumentNode,
    EvidenceNode
}
import from helpers { parse_json }

glob llm = Model(model_name="claude-haiku-4-5-20251001");

node EntityExtractorAgent {
    has extraction_complete: bool = False;

    """
    You are a healthcare fraud detection expert analyzing Medicare billing documents.

    Analyze the provided documents and extract all suspicious findings.

    For each finding return a JSON object with:
    - evidence_type: one of "billing_anomaly", "email_evidence", "pattern", "provider", "amount"
    - description: specific finding with numbers and details
    - source_doc: which document this came from
    - confidence: float 0.0 to 1.0

    Flag any CPT code billed more than 70% of the time as a billing anomaly.
    National average for 99215 (highest complexity) is only 15-40%.
    Flag any emails showing intent to commit fraud.
    Flag any patterns of systematic overbilling.

    Return only a valid JSON array of findings. No other text.
    """
    def extract_entities(
        documents: list[str],
        cms_benchmark: dict
    ) -> str by llm();

    can run with entry {
        print("Entity Extractor firing!");

        # Collect all documents from root
        docs: list[str] = [];
        for doc in [root -->][?:DocumentNode] {
            doc_text = "FILE: " + doc.filename + "\n";
            doc_text = doc_text + "TYPE: " + doc.doc_type + "\n";
            doc_text = doc_text + "CONTENT:\n" + doc.content;
            docs.append(doc_text);
        }

        print("Documents found: " + str(len(docs)));

        if len(docs) == 0 {
            print("No documents found - skipping extraction");
            self.extraction_complete = True;
            visitor.extraction_done = True;
            return;
        }

        # CMS benchmark for comparison
        benchmark = {
            "99211": 0.05,
            "99212": 0.15,
            "99213": 0.35,
            "99214": 0.30,
            "99215": 0.15
        };

        # Call Claude
        raw = self.extract_entities(docs, benchmark);
        print("Raw LLM output received");

        findings = parse_json(raw);

        # Create EvidenceNodes on root
        if isinstance(findings, list) {
            for finding in findings {
                ev = EvidenceNode();
                ev.evidence_type = "billing_anomaly";
                ev.description = "extracted finding";
                ev.source_doc = "document";
                ev.confidence = 0.9;

                if "evidence_type" in finding {
                    ev.evidence_type = finding["evidence_type"];
                }
                if "description" in finding {
                    ev.description = finding["description"];
                }
                if "source_doc" in finding {
                    ev.source_doc = finding["source_doc"];
                }
                if "confidence" in finding {
                    ev.confidence = finding["confidence"];
                }

                root ++> ev;
                print("Evidence found: " + ev.evidence_type);
            }
        }

        self.extraction_complete = True;
        visitor.extraction_done = True;
        print("Extraction complete!");
    }
}