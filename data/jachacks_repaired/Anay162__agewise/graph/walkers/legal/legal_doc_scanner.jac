"""LegalDocScanner walker — extracts structured data from legal documents."""

import from graph.nodes.patient { Patient }
import from graph.nodes.legal_document { LegalDocument }
import from abilities.llm_abilities { extract_legal_document_data }

walker LegalDocScanner {

    can start with Patient entry {
        visit [-->];
    }

    can scan with LegalDocument entry {
        if here.key_provisions != [] {
            disengage;  # Already scanned
        }

        raw = extract_legal_document_data(
            document_text="",  # loaded from source_doc_id in real impl
            doc_type=here.doc_type
        );

        here.parties = raw.get("parties", []);
        here.executor_agent = raw.get("executor_agent", raw.get("agent", ""));
        here.key_provisions = raw.get("key_provisions", []);
        here.plain_english_summary = raw.get("plain_english_summary", "");
        print(f"[LegalDocScanner] Scanned {here.doc_type} doc {here.legal_doc_id}");
    }
}
