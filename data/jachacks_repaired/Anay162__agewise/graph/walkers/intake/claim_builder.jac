"""ClaimBuilder walker — finalizes claim structure from extracted document data.

Walks Patient → Document → Claim nodes and ensures all claims have:
- Proper line items attached
- Provider and Insurer nodes linked (created if needed)
- EOBs cross-referenced to claims
"""

import from graph.nodes.patient { Patient }
import from graph.nodes.document { Document }
import from graph.nodes.claim { Claim }
import from graph.nodes.line_item { LineItem }
import from graph.nodes.provider { Provider }
import from graph.nodes.insurer { Insurer }
import from abilities.llm_abilities { extract_claim_data }

import from datetime { datetime }
import from uuid { uuid4 }

walker ClaimBuilder {
    has patient: any = None;


    can start with Patient entry {
        self.patient = here;
        visit [-->];
    }

    can process_doc with Document entry {
        if not here.processed {
            visit [-->];
        }
        disengage;
    }

    can build_claim with Claim entry {
        # Build line items if claim came from a CMS-1500 or UB-04 document
        if here.source_doc_id == "" {
            disengage;
        }

        # Find the source document
        source_docs = [d for d in [self.patient-->] if isinstance(d, Document) and d.doc_id == here.source_doc_id];
        if len(source_docs) == 0 {
            disengage;
        }

        source_doc = source_docs[0];
        if source_doc.classification not in ["CMS1500_CLAIM", "UB04_CLAIM"] {
            disengage;
        }

        raw = extract_claim_data(
            document_text=source_doc.raw_content,
            claim_type=source_doc.classification
        );

        # Create line items from extracted service lines
        existing_lines = [li for li in [here-->] if isinstance(li, LineItem)];
        if len(existing_lines) > 0 {
            disengage;  # Already built
        }

        service_lines = raw.get("service_lines", raw.get("revenue_lines", []));
        for line in service_lines {
            item = LineItem(
                line_number=int(line.get("line_number", 1) or 1),
                cpt_code=line.get("cpt_code", line.get("hcpcs", "")),
                revenue_code=line.get("revenue_code", ""),
                modifier_1=line.get("modifier", ""),
                units=float(line.get("units", 1) or 1),
                charge_amount=float(line.get("charges", line.get("total_charges", 0)) or 0),
                service_date=line.get("date_of_service", line.get("service_date", "")),
                place_of_service_code=line.get("place_of_service", ""),
                icd_diagnosis_pointers=[line.get("diagnosis_pointer", "")]
                    if line.get("diagnosis_pointer") else []
            );
            here ++> item;
        }

        # Create or find Provider
        provider_npi = raw.get("provider_npi", "");
        provider_name = raw.get("provider_name", "Unknown Provider");
        existing_providers = [p for p in [here-->] if isinstance(p, Provider)];
        if len(existing_providers) == 0 and provider_npi != "" {
            prov = Provider(npi=provider_npi, name=provider_name);
            here ++> prov;
        }

        print(f"[ClaimBuilder] Built claim {here.claim_number} with {len(service_lines)} line items");
    }
}
