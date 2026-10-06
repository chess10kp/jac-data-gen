"""AmendmentDrafter walker — generates draft legal amendments for attorney review."""

import from graph.nodes.patient { Patient }
import from graph.nodes.legal_document { LegalDocument }
import from abilities.llm_abilities { draft_legal_amendment }

import from datetime { datetime }

walker AmendmentDrafter {
    has change_description: str = "",
        target_doc_type: str = "";

    can start with Patient entry {
        visit [-->];
    }

    can draft with LegalDocument entry {
        if self.target_doc_type != "" and here.doc_type != self.target_doc_type {
            disengage;
        }
        if self.change_description == "" {
            disengage;
        }

        draft = draft_legal_amendment(
            original_document_type=here.doc_type,
            original_date=here.effective_date,
            change_description=self.change_description,
            jurisdiction=here.jurisdiction,
            grantor_name=here.parties[0] if here.parties else ""
        );

        print(f"[AmendmentDrafter] Draft generated for {here.doc_type} {here.legal_doc_id}");
        print("  NOTE: Draft requires attorney review before execution.");
        report {"doc_id": here.legal_doc_id, "draft": draft};
    }
}
