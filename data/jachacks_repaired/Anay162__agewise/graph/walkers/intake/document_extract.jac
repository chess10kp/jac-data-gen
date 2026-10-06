"""DocumentExtract walker — extracts structured data from classified Documents.

Walks classified Document nodes and uses by llm() functions to pull out
structured fields based on the document type. Creates appropriate downstream
nodes (Claim, EOB, LegalDocument) from extracted data.
"""

import from graph.nodes.patient { Patient }
import from graph.nodes.document { Document }
import from graph.nodes.eob { EOB }
import from graph.nodes.claim { Claim }
import from graph.nodes.legal_document { LegalDocument }
import from abilities.llm_abilities { extract_eob_data, extract_claim_data, extract_legal_document_data }

import from datetime { datetime }
import from uuid { uuid4 }

# EOB and MSN document types
glob EOB_TYPES = ["EOB", "MSN_PART_A", "MSN_PART_B"];

# Claim document types
glob CLAIM_TYPES = ["CMS1500_CLAIM", "UB04_CLAIM", "MEDICAL_BILL"];

# Legal document types
glob LEGAL_TYPES = ["HIPAA_AUTH", "POWER_OF_ATTORNEY", "WILL", "TRUST", "BENEFICIARY_FORM"];

walker DocumentExtract {
    has patient_ref: any = None;


    can start with Patient entry {
        self.patient_ref = here;
        visit [-->];
    }

    can extract with Document entry {
        # Skip already-processed or unclassified docs
        if here.processed or here.classification == "UNKNOWN" {
            disengage;
        }

        classification = here.classification;
        doc_text = here.raw_content;

        if classification in EOB_TYPES {
            raw = extract_eob_data(document_text=doc_text, eob_type=classification);
            eob = EOB(
                eob_id=str(uuid4()),
                eob_type=classification,
                payer_name=raw.get("payer_name", ""),
                adjudication_date=raw.get("adjudication_date", ""),
                total_billed=float(raw.get("total_billed", 0) or 0),
                medicare_approved=float(raw.get("medicare_approved", 0) or 0),
                medicare_paid=float(raw.get("medicare_paid", 0) or 0),
                patient_responsibility=float(raw.get("patient_responsibility", 0) or 0),
                non_covered_charges=float(raw.get("non_covered_charges", 0) or 0),
                benefit_days_used=int(raw.get("benefit_days_used", 0) or 0),
                appeal_deadline=raw.get("appeal_deadline", ""),
                denial_codes=raw.get("denial_codes", []),
                denial_reasons=raw.get("denial_reasons", []),
                source_doc_id=here.doc_id,
                created_at=datetime.utcnow().isoformat()
            );
            # EOB lives off the patient node; claim_builder will link it to the claim
            here ++> eob;
            print(f"[DocumentExtract] Created EOB {eob.eob_id} from doc {here.doc_id}");

        } elif classification in CLAIM_TYPES {
            raw = extract_claim_data(document_text=doc_text, claim_type=classification);
            claim_type_code = "UB04" if classification == "UB04_CLAIM" else "CMS1500";
            claim = Claim(
                claim_number=raw.get("claim_number", str(uuid4())[:8].upper()),
                claim_type=claim_type_code,
                service_date_start=raw.get("service_date_start", ""),
                service_date_end=raw.get("service_date_end", ""),
                total_charges=float(raw.get("total_charges", 0) or 0),
                status="PROCESSING",
                source_doc_id=here.doc_id,
                created_at=datetime.utcnow().isoformat()
            );
            here ++> claim;
            print(f"[DocumentExtract] Created Claim {claim.claim_number} from doc {here.doc_id}");

        } elif classification in LEGAL_TYPES {
            raw = extract_legal_document_data(document_text=doc_text, doc_type=classification);
            legal_doc = LegalDocument(
                legal_doc_id=str(uuid4()),
                doc_type=classification,
                effective_date=raw.get("effective_date", ""),
                expiry_date=raw.get("expiry_date", ""),
                parties=raw.get("parties", []),
                executor_agent=raw.get("executor_agent", raw.get("agent", "")),
                source_doc_id=here.doc_id,
                status="ACTIVE",
                created_at=datetime.utcnow().isoformat()
            );
            here ++> legal_doc;
            print(f"[DocumentExtract] Created LegalDocument {legal_doc.legal_doc_id} from doc {here.doc_id}");
        }

        here.processed = True;
    }
}
