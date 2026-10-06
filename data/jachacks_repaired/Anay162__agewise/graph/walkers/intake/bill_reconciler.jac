"""BillReconciler walker — matches bills to EOBs and flags discrepancies.

A patient receives both: (1) a bill from the provider and (2) an EOB from
Medicare showing what should have been paid. This walker compares them and
flags when the patient is being billed more than they should owe.
"""

import from graph.nodes.patient { Patient }
import from graph.nodes.claim { Claim }
import from graph.nodes.eob { EOB }
import from graph.nodes.dispute { Dispute }
import from graph.nodes.notification { Notification }

import from datetime { datetime }
import from uuid { uuid4 }

# Threshold: flag if billed patient responsibility exceeds EOB patient
# responsibility by more than this amount
glob DISCREPANCY_THRESHOLD = 10.0;

walker BillReconciler {

    can start with Patient entry {
        visit [-->];
    }

    can check_claim with Claim entry {
        # Get all EOBs for this claim
        eobs = [e for e in [here-->] if isinstance(e, EOB)];
        if len(eobs) == 0 {
            disengage;
        }

        for eob in eobs {
            expected_patient_responsibility = eob.patient_responsibility;
            billed_patient_responsibility = here.patient_responsibility;

            discrepancy = billed_patient_responsibility - expected_patient_responsibility;

            if discrepancy > DISCREPANCY_THRESHOLD {
                # Flag this as a potential overbilling
                dispute = Dispute(
                    dispute_id=str(uuid4()),
                    error_type="BILL_EOB_MISMATCH",
                    description=(
                        f"Bill charges patient ${billed_patient_responsibility:.2f} "
                        f"but EOB shows patient responsibility of ${expected_patient_responsibility:.2f}. "
                        f"Discrepancy: ${discrepancy:.2f}"
                    ),
                    amount_disputed=discrepancy,
                    expected_amount=expected_patient_responsibility,
                    status="OPEN",
                    flagged_date=datetime.utcnow().isoformat(),
                    confidence_score=0.85,
                    severity="HIGH" if discrepancy > 100 else "MEDIUM",
                    citations=["42 CFR 424.55 — Limitation on Charges"]
                );
                here ++> dispute;
                print(
                    f"[BillReconciler] Flagged discrepancy on claim {here.claim_number}: "
                    f"${discrepancy:.2f} overcharge"
                );
            }
        }
    }
}
