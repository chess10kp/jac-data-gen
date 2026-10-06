"""EOBParser walker — specialized parser for Medicare MSN and MA EOB documents.

Handles the specific formats of Medicare Summary Notices (Part A and Part B)
and Medicare Advantage EOBs, creating properly linked EOB and Claim nodes.
"""

import from graph.nodes.patient { Patient }
import from graph.nodes.document { Document }
import from graph.nodes.eob { EOB }
import from graph.nodes.claim { Claim }
import from graph.nodes.line_item { LineItem }
import from abilities.llm_abilities { extract_eob_data }

import from datetime { datetime }
import from uuid { uuid4 }

walker EOBParser {

    can start with Patient entry {
        visit [-->];
    }

    can parse_eob_doc with Document entry {
        if here.classification not in ["MSN_PART_A", "MSN_PART_B", "EOB"] {
            disengage;
        }

        raw = extract_eob_data(
            document_text=here.raw_content,
            eob_type=here.classification
        );

        # Find or create the matching Claim for this EOB
        claim_number = raw.get("claim_number", "");
        matching_claims = [c for c in [here<-->] if isinstance(c, Claim) and c.claim_number == claim_number];

        if len(matching_claims) == 0 {
            # Create a new claim from EOB data
            claim = Claim(
                claim_number=claim_number or str(uuid4())[:8].upper(),
                claim_type="CMS1500",
                service_date_start=raw.get("service_date_start", ""),
                service_date_end=raw.get("service_date_end", raw.get("service_date_start", "")),
                total_charges=float(raw.get("total_billed", 0) or 0),
                amount_paid=float(raw.get("medicare_paid", 0) or 0),
                patient_responsibility=float(raw.get("patient_responsibility", 0) or 0),
                status="PAID",
                source_doc_id=here.doc_id,
                created_at=datetime.utcnow().isoformat()
            );
            here ++> claim;
        } else {
            claim = matching_claims[0];
        }

        # Create EOB node
        eob = EOB(
            eob_id=str(uuid4()),
            eob_type=here.classification,
            payer_name=raw.get("payer_name", "Medicare"),
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
        claim ++> eob;

        # Create LineItem nodes for each service line in the EOB
        service_lines = raw.get("service_lines", []);
        for (i, line) in enumerate(service_lines) {
            item = LineItem(
                line_number=i + 1,
                cpt_code=line.get("cpt_code", ""),
                units=float(line.get("units", 1) or 1),
                charge_amount=float(line.get("billed", 0) or 0),
                allowed_amount=float(line.get("allowed", 0) or 0),
                paid_amount=float(line.get("paid", 0) or 0),
                service_date=line.get("date", ""),
                description=line.get("description", "")
            );
            claim ++> item;
        }

        print(f"[EOBParser] Parsed EOB {eob.eob_id} with {len(service_lines)} service lines");
        here.processed = True;
    }
}
