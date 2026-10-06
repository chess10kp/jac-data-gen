"""DiagnosisCodeAuditor walker — validates ICD-10 code specificity per FY2026 guidelines."""

import from graph.nodes.patient { Patient }
import from graph.nodes.claim { Claim }
import from graph.nodes.line_item { LineItem }
import from graph.nodes.dispute { Dispute }
import from abilities.llm_abilities { validate_icd10_specificity }
import from reference_data.db { query_icd10 }

import from datetime { datetime }
import from uuid { uuid4 }

walker DiagnosisCodeAuditor {

    can start with Patient entry {
        visit [-->];
    }

    can check_claim with Claim entry {
        visit [-->];
    }

    can audit_line_item with LineItem entry {
        if len(here.icd_diagnosis_pointers) == 0 {
            disengage;
        }

        for pointer in here.icd_diagnosis_pointers {
            if pointer == "" {
                continue;
            }

            # Look up code in DB
            code_info = query_icd10(pointer);
            if code_info is None {
                print(f"[DiagnosisCodeAuditor] Unknown ICD-10 code: {pointer}");
                continue;
            }

            # Flag header codes (not billable)
            if code_info.get("is_header", False) {
                dispute = Dispute(
                    dispute_id=str(uuid4()),
                    error_type="CODING_ERROR",
                    description=(
                        f"ICD-10 code {pointer} is a category header code (not billable). "
                        f"A more specific code is required per FY2026 ICD-10-CM guidelines."
                    ),
                    amount_disputed=0.0,
                    status="OPEN",
                    flagged_date=datetime.utcnow().isoformat(),
                    confidence_score=0.95,
                    severity="MEDIUM",
                    citations=["ICD-10-CM Official Guidelines — Specificity requirement"]
                );
                here ++> dispute;
                here.has_errors = True;
                here.error_count += 1;
                print(f"[DiagnosisCodeAuditor] Header code used: {pointer}");
            }
        }
    }
}
