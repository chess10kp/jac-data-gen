"""FeeScheduleAuditor walker — checks line item charges vs. Medicare fee schedule.

Walks Patient → Claim → LineItem nodes and cross-references each CPT/HCPCS
code against the Medicare Physician Fee Schedule in PostgreSQL. Flags line items
where the billed amount exceeds the fee schedule allowable by more than 10%.
"""

import from graph.nodes.patient { Patient }
import from graph.nodes.claim { Claim }
import from graph.nodes.line_item { LineItem }
import from graph.nodes.dispute { Dispute }
import from abilities.llm_abilities { assess_billing_error }
import from reference_data.db { query_fee_schedule }

import from datetime { datetime }
import from uuid { uuid4 }

glob FEE_SCHEDULE_OVERAGE_THRESHOLD = 0.10;  # 10% over allowable = flag

walker FeeScheduleAuditor {
    has patient_state: str = "XX";   # 2-letter state code for locality pricing

    can start with Patient entry {
        self.patient_state = here.state or "XX";
        visit [-->];
    }

    can check_claim with Claim entry {
        visit [-->];
    }

    can audit_line_item with LineItem entry {
        if here.cpt_code == "" or here.charge_amount == 0 {
            disengage;
        }

        # Look up fee schedule rate in PostgreSQL
        rate = query_fee_schedule(
            cpt_code=here.cpt_code,
            state=self.patient_state
        );

        if rate is None or rate == 0 {
            disengage;  # Code not in fee schedule (e.g., HCPCS supply code)
        }

        here.fee_schedule_rate = rate;
        adjusted_rate = rate * here.units;
        overage = here.charge_amount - adjusted_rate;
        overage_pct = overage / adjusted_rate if adjusted_rate > 0 else 0;

        here.fee_schedule_overage = overage;

        if overage_pct > FEE_SCHEDULE_OVERAGE_THRESHOLD {
            here.has_errors = True;
            here.error_count += 1;

            dispute = Dispute(
                dispute_id=str(uuid4()),
                error_type="FEE_SCHEDULE_OVERAGE",
                description=(
                    f"CPT {here.cpt_code} billed at ${here.charge_amount:.2f} "
                    f"but Medicare fee schedule allows ${adjusted_rate:.2f} "
                    f"({overage_pct*100:.1f}% over limit)"
                ),
                amount_disputed=overage,
                expected_amount=adjusted_rate,
                status="OPEN",
                flagged_date=datetime.utcnow().isoformat(),
                confidence_score=0.90,
                severity="HIGH" if overage > 100 else "MEDIUM",
                citations=[
                    "42 CFR 414.20 — Computation of fee schedule amounts",
                    f"CMS Medicare Physician Fee Schedule {here.cpt_code}"
                ]
            );
            here ++> dispute;
            print(
                f"[FeeScheduleAuditor] Flagged {here.cpt_code}: "
                f"${here.charge_amount:.2f} billed vs ${adjusted_rate:.2f} allowed "
                f"(+{overage_pct*100:.1f}%)"
            );
        }
    }
}
