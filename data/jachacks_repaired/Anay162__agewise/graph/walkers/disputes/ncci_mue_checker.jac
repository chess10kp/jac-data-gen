"""NCCIMUEChecker walker — checks NCCI Medically Unlikely Edit limits.

Each CPT/HCPCS code has a Medically Unlikely Edit (MUE) — the maximum
number of units that could reasonably be provided in a single day.
This walker flags any line item where billed units exceed the MUE.
"""

import from graph.nodes.patient { Patient }
import from graph.nodes.claim { Claim }
import from graph.nodes.line_item { LineItem }
import from graph.nodes.dispute { Dispute }
import from reference_data.db { query_ncci_mue }

import from datetime { datetime }
import from uuid { uuid4 }

walker NCCIMUEChecker {

    can start with Patient entry {
        visit [-->];
    }

    can check_claim with Claim entry {
        visit [-->];
    }

    can check_line_item with LineItem entry {
        if here.cpt_code == "" or here.units <= 1 {
            disengage;
        }

        mue = query_ncci_mue(cpt_code=here.cpt_code);
        if mue is None {
            disengage;
        }

        # Use practitioner MUE limit (facility limit may differ)
        mue_limit = mue.get("practitioner_mue", 0);
        here.mue_limit = mue_limit;

        if mue_limit > 0 and here.units > mue_limit {
            excess_units = here.units - mue_limit;
            excess_amount = excess_units * (here.charge_amount / here.units if here.units > 0 else 0);

            dispute = Dispute(
                dispute_id=str(uuid4()),
                error_type="MUE_VIOLATION",
                description=(
                    f"CPT {here.cpt_code} billed {here.units} units but MUE limit is {mue_limit}. "
                    f"Excess: {excess_units} units (${excess_amount:.2f}). "
                    f"Rationale: {mue.get('rationale', 'per CMS guidelines')}"
                ),
                amount_disputed=excess_amount,
                expected_amount=here.charge_amount - excess_amount,
                status="OPEN",
                flagged_date=datetime.utcnow().isoformat(),
                confidence_score=0.92,
                severity="HIGH" if excess_amount > 50 else "MEDIUM",
                citations=[
                    f"CMS NCCI MUE: {here.cpt_code} limit = {mue_limit}",
                    "CMS Medically Unlikely Edits Policy"
                ]
            );
            here ++> dispute;
            here.has_errors = True;
            here.ncci_flags = here.ncci_flags + [f"MUE:{mue_limit}"];
            here.error_count += 1;
            print(
                f"[NCCIMUEChecker] MUE violation: {here.cpt_code} billed {here.units} "
                f"units (limit {mue_limit}), excess ${excess_amount:.2f}"
            );
    }
}
}
