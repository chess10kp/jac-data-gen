"""CoveragePolicyChecker walker — flags services not covered under the patient's policy."""

import from graph.nodes.patient { Patient }
import from graph.nodes.claim { Claim }
import from graph.nodes.line_item { LineItem }
import from graph.nodes.policy { Policy }
import from graph.nodes.dispute { Dispute }

import from datetime { datetime }
import from uuid { uuid4 }

walker CoveragePolicyChecker {
    has active_policies: list = [];


    can start with Patient entry {
        # Get active policies
        self.active_policies = [p for p in [here-->] if isinstance(p, Policy) and p.termination_date == ""];
        visit [-->];
    }

    can check_claim with Claim entry {
        visit [-->];
    }

    can check_line_item with LineItem entry {
        if here.cpt_code == "" or len(self.active_policies) == 0 {
            disengage;
        }

        # Basic coverage check — coinsurance overage check
        for policy in self.active_policies {
            if policy.plan_type in ["MEDICARE_PART_B", "MEDICARE_PART_A"] {
                # Medicare covers most medically necessary services
                # Flag if paid amount is 0 and not a non-covered code
                if here.paid_amount == 0 and here.charge_amount > 0 {
                    dispute = Dispute(
                        dispute_id=str(uuid4()),
                        error_type="NOT_COVERED",
                        description=(
                            f"CPT {here.cpt_code} shows $0 paid by {policy.plan_name or policy.plan_type}. "
                            f"Verify this service is covered and medical necessity documentation is present."
                        ),
                        amount_disputed=here.charge_amount,
                        status="OPEN",
                        flagged_date=datetime.utcnow().isoformat(),
                        confidence_score=0.60,
                        severity="MEDIUM",
                        citations=["42 CFR 411.15 — Particular services excluded from coverage"]
                    );
                    here ++> dispute;
                    here.has_errors = True;
                    here.error_count += 1;
                    print(f"[CoveragePolicyChecker] Possible non-coverage: {here.cpt_code}");
                }
            }
        }
    }
}
