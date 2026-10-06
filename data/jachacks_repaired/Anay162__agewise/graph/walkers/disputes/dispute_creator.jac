"""DisputeCreator walker — creates Dispute nodes from all detected errors.

This walker is the aggregator: it runs AFTER all audit walkers have flagged
line items, then calls assess_billing_error() via by llm() for each flagged
item to get a richer dispute assessment with regulatory citations.
"""

import from graph.nodes.patient { Patient }
import from graph.nodes.claim { Claim }
import from graph.nodes.line_item { LineItem }
import from graph.nodes.dispute { Dispute }
import from abilities.llm_abilities { assess_billing_error }

import from datetime { datetime }
import from uuid { uuid4 }

walker DisputeCreator {

    can start with Patient entry {
        visit [-->];
    }

    can check_claim with Claim entry {
        visit [-->];
    }

    can check_line_item with LineItem entry {
        if not here.has_errors {
            disengage;
        }

        # Call LLM for richer assessment of already-flagged items
        assessment = assess_billing_error(
            cpt_code=here.cpt_code,
            description=here.description,
            billed_amount=here.charge_amount,
            fee_schedule_rate=here.fee_schedule_rate,
            units=here.units,
            mue_limit=here.mue_limit,
            ncci_flags=here.ncci_flags,
            modifier=here.modifier_1,
            diagnosis_pointers=here.icd_diagnosis_pointers,
            diagnosis_codes=[]
        );

        if assessment.get("has_error", False) {
            # Update or create a comprehensive dispute node
            existing_disputes = [d for d in [here-->] if isinstance(d, Dispute)];

            if len(existing_disputes) == 0 {
                # No dispute yet — create one from LLM assessment
                dispute = Dispute(
                    dispute_id=str(uuid4()),
                    error_type=assessment.get("error_type", "BILLING_ERROR"),
                    description=assessment.get("description", ""),
                    amount_disputed=float(assessment.get("amount_disputed", 0) or 0),
                    expected_amount=here.charge_amount - float(assessment.get("amount_disputed", 0) or 0),
                    status="OPEN",
                    flagged_date=datetime.utcnow().isoformat(),
                    confidence_score=float(assessment.get("confidence", 0.5) or 0.5),
                    severity="HIGH" if float(assessment.get("amount_disputed", 0) or 0) > 100 else "MEDIUM",
                    citations=[assessment.get("regulatory_citation", "")] if assessment.get("regulatory_citation") else []
                );
                here ++> dispute;
            } else {
                # Enrich the existing dispute with LLM citations
                for d in existing_disputes {
                    if assessment.get("regulatory_citation") {
                        d.citations = list(set(d.citations + [assessment.get("regulatory_citation", "")]));
                    }
                }
            }
        }
    }
}
