"""HIPAAAuthGenerator walker — generates pre-filled HIPAA authorization forms."""

import from graph.nodes.patient { Patient }
import from graph.nodes.records_transfer { RecordsTransfer }
import from graph.nodes.legal_document { LegalDocument }
import from abilities.llm_abilities { generate_hipaa_auth_form }
import from datetime { datetime }
import from uuid { uuid4 }

walker HIPAAAuthGenerator {
    has forms_generated: int = 0;

    can generate with Patient entry {
        pending_transfers = [
            n for n in [here-->]
            if isinstance(n, RecordsTransfer)
            and n.status == "PENDING"
            and not n.hipaa_auth_generated
        ];

        for transfer in pending_transfers {
            form_content = generate_hipaa_auth_form(
                patient_name=here.name,
                patient_dob=here.dob,
                patient_address=here.address,
                purpose=transfer.purpose,
                sending_provider=transfer.sending_provider_name,
                receiving_provider=transfer.receiving_provider_name,
                authorization_date=datetime.utcnow().isoformat()[:10]
            );

            hipaa_doc = LegalDocument(
                legal_doc_id=str(uuid4()),
                doc_type="HIPAA_AUTHORIZATION",
                title=f"HIPAA Auth for {transfer.purpose}",
                plain_english_summary=form_content.get("form_text", ""),
                status="PENDING_SIGNATURE",
                effective_date=datetime.utcnow().isoformat()[:10],
                expiry_date=form_content.get("expiry_date", ""),
                created_at=datetime.utcnow().isoformat()
            );
            here ++> hipaa_doc;
            transfer.hipaa_auth_generated = True;
            self.forms_generated += 1;
        }

        report {"patient": here.name, "forms_generated": self.forms_generated};
    }
}
