"""NCCIPTPChecker walker — checks NCCI Procedure-to-Procedure edits.

For each claim, walks all LineItem nodes pairwise and checks whether any
pair of CPT codes violates an NCCI Column One/Column Two edit (meaning
one code bundles the other and they can't be billed together without
a valid modifier).

NCCI PTP data is loaded from CMS quarterly files into PostgreSQL.
"""

import from graph.nodes.patient { Patient }
import from graph.nodes.claim { Claim }
import from graph.nodes.line_item { LineItem }
import from graph.nodes.dispute { Dispute }
import from reference_data.db { query_ncci_ptp }

import from datetime { datetime }
import from uuid { uuid4 }
import from itertools { combinations }

walker NCCIPTPChecker {

    can start with Patient entry {
        visit [-->];
    }

    can check_claim with Claim entry {
        # Gather all line items for this claim
        line_items = [li for li in [here-->] if isinstance(li, LineItem) and li.cpt_code != ""];
        if len(line_items) < 2 {
            disengage;
        }

        # Check all pairs
        for (item_a, item_b) in combinations(line_items, 2) {
            col1 = item_a.cpt_code;
            col2 = item_b.cpt_code;

            edit = query_ncci_ptp(column1_code=col1, column2_code=col2);

            if edit is None {
                # Try reversed (NCCI is directional — col1 bundles col2)
                edit = query_ncci_ptp(column1_code=col2, column2_code=col1);
                if edit is not None {
                    # Swap so col1 is the bundling code
                    (col1, col2) = (col2, col1);
                    (item_a, item_b) = (item_b, item_a);
                }
            }

            if edit is None {
                continue;
            }

            modifier_indicator = edit.get("modifier_indicator", "0");
            # modifier_indicator 0 = cannot bill together even with modifier
            # modifier_indicator 1 = can override with modifier 59/XS/XU/XP/XE

            has_bypass_modifier = any(
                m in ["59", "XS", "XU", "XP", "XE"]
                for m in [item_a.modifier_1, item_a.modifier_2,
                          item_b.modifier_1, item_b.modifier_2]
            );

            if modifier_indicator == "0" or not has_bypass_modifier {
                violation_desc = (
                    f"NCCI PTP edit: CPT {col2} is bundled into CPT {col1} "
                    f"and cannot be billed separately"
                );
                if modifier_indicator == "1" and not has_bypass_modifier {
                    violation_desc += ". A modifier (59/XS/XU/XP/XE) may allow separate billing if the service is distinct.";
                }

                dispute = Dispute(
                    dispute_id=str(uuid4()),
                    error_type="NCCI_PTP_VIOLATION",
                    description=violation_desc,
                    amount_disputed=item_b.charge_amount,  # the bundled code's charge
                    expected_amount=0.0,
                    status="OPEN",
                    flagged_date=datetime.utcnow().isoformat(),
                    confidence_score=0.95,
                    severity="HIGH",
                    citations=[
                        f"CMS NCCI PTP Edit: {col1}/{col2}",
                        "42 CFR 414.40 — Bundling of services"
                    ]
                );
                item_b ++> dispute;
                item_b.has_errors = True;
                item_b.ncci_flags = item_b.ncci_flags + [f"PTP:{col1}"];
                item_b.error_count += 1;
                print(
                    f"[NCCIPTPChecker] PTP violation: {col1} bundles {col2} "
                    f"on claim (${item_b.charge_amount:.2f} disputed)"
                );
    }
}
}
}
