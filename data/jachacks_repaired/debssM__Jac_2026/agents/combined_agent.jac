# agents/combined_agent.jac

import from byllm.llm { Model }
import from nodes.data_nodes {
    DocumentNode,
    EvidenceNode,
    TimelineNode,
    FalsityNode,
    ScientorNode,
    MaterialityNode,
    CausationNode,
    CaseMemoNode
}
import from helpers { parse_json }

glob llm = Model(model_name="claude-sonnet-4-20250514");

node CombinedAnalysisAgent {
    has analysis_complete: bool = False;

    """
    You are a False Claims Act legal and healthcare fraud expert.
    Analyze the provided Medicare billing documents in a single pass.

    Return ONLY a valid JSON object with these exact top-level keys:

    "evidence": list of objects, each with:
      - evidence_type: "billing_anomaly" | "email_evidence" | "pattern" | "provider" | "amount"
      - description: specific finding with numbers and details
      - source_doc: filename this came from
      - confidence: float 0.0-1.0
      Flag CPT 99215 billed >70% of visits (national avg is 15-40%).
      Flag emails showing intent to commit fraud.

    "timeline": object with:
      - fraud_start: "YYYY-MM"
      - fraud_end: "YYYY-MM"
      - total_duration_months: integer
      - events: list of short strings in chronological order

    "fca": object with:
      - falsity:     { score: float 0-1, type: "factual"|"legal",                        evidence: [str] }
      - scienter:    { score: float 0-1, type: "actual"|"deliberate_ignorance"|"reckless", evidence: [str] }
      - materiality: { score: float 0-1, relied: bool,                                   evidence: [str] }
      - causation:   { score: float 0-1, chain: str,                                     evidence: [str] }

    "damages": object with:
      - defendant: name of the fraudulent provider
      - total_false_claims: integer
      - overpayment_per_claim: float
      - base_damages: float
      - treble_damages: float  (= base_damages x 3)
      - total_min_exposure: float  (= treble_damages + 13946 x total_false_claims)
      - total_max_exposure: float  (= treble_damages + 27894 x total_false_claims)
      - case_summary: two-sentence plain-English summary of the fraud

    Return ONLY valid JSON. No other text.
    """
    def analyze_all(documents: list[str]) -> str by llm();

    can run with entry {
        print("Combined Analysis Agent firing!");

        docs: list[str] = [];
        for doc in [root -->][?:DocumentNode] {
            doc_text = "FILE: " + doc.filename + "\nTYPE: " + doc.doc_type + "\nCONTENT:\n" + doc.content;
            docs.append(doc_text);
        }

        print("Documents found: " + str(len(docs)));

        if len(docs) == 0 {
            print("No documents found - skipping analysis");
            self.analysis_complete = True;
            return;
        }

        raw = self.analyze_all(docs);
        print("LLM output received: " + raw[:200]);

        result = parse_json(raw);
        if not isinstance(result, dict) or len(result) == 0 {
            print("ERROR: Failed to parse LLM response. Raw output: " + raw);
            result = {};
        }

        # ── Evidence nodes ────────────────────────────────
        evidence_list = result.get("evidence", []);
        if isinstance(evidence_list, list) {
            for finding in evidence_list {
                ev = EvidenceNode();
                ev.evidence_type = finding.get("evidence_type", "billing_anomaly");
                ev.description   = finding.get("description", "");
                ev.source_doc    = finding.get("source_doc", "");
                ev.confidence    = finding.get("confidence", 0.9);
                root ++> ev;
                print("Evidence: " + ev.evidence_type);
            }
        }

        # ── Timeline node ─────────────────────────────────
        tl_data = result.get("timeline", {});
        tl = TimelineNode();
        tl.events                = tl_data.get("events", []);
        tl.fraud_start           = tl_data.get("fraud_start", "unknown");
        tl.fraud_end             = tl_data.get("fraud_end", "unknown");
        tl.total_duration_months = tl_data.get("total_duration_months", 0);
        root ++> tl;

        # ── FCA element nodes ─────────────────────────────
        fca = result.get("fca", {});

        f_data = fca.get("falsity", {});
        f_node = FalsityNode();
        f_node.evidence_list  = f_data.get("evidence", []);
        f_node.falsity_type   = f_data.get("type", "factual");
        f_node.strength_score = f_data.get("score", 0.0);
        root ++> f_node;

        s_data = fca.get("scienter", {});
        s_node = ScientorNode();
        s_node.evidence_list  = s_data.get("evidence", []);
        s_node.knowledge_type = s_data.get("type", "actual");
        s_node.strength_score = s_data.get("score", 0.0);
        root ++> s_node;

        m_data = fca.get("materiality", {});
        m_node = MaterialityNode();
        m_node.evidence_list    = m_data.get("evidence", []);
        m_node.government_relied = m_data.get("relied", False);
        m_node.strength_score   = m_data.get("score", 0.0);
        root ++> m_node;

        c_data = fca.get("causation", {});
        c_node = CausationNode();
        c_node.evidence_list  = c_data.get("evidence", []);
        c_node.causal_chain   = c_data.get("chain", "");
        c_node.strength_score = c_data.get("score", 0.0);
        root ++> c_node;

        # ── Case memo node ────────────────────────────────
        dmg = result.get("damages", {});
        overall = (f_node.strength_score + s_node.strength_score + m_node.strength_score + c_node.strength_score) / 4.0;

        memo = CaseMemoNode();
        memo.defendant          = dmg.get("defendant", "Unknown");
        memo.total_false_claims = dmg.get("total_false_claims", 0);
        memo.base_damages       = dmg.get("base_damages", 0.0);
        memo.treble_damages     = dmg.get("treble_damages", 0.0);
        memo.per_claim_penalty  = 13946.0;
        memo.total_exposure     = dmg.get("total_max_exposure", 0.0);
        memo.overall_strength   = str(overall);
        memo.gap_analysis       = [];
        memo.case_summary       = dmg.get("case_summary", "");
        root ++> memo;

        self.analysis_complete = True;
        print("Analysis complete! Defendant: " + memo.defendant);
        print("Treble damages: " + str(memo.treble_damages));
        print("Total exposure: " + str(memo.total_exposure));
    }
}
