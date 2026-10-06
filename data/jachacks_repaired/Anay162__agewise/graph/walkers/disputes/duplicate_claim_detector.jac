"""DuplicateClaimDetector walker — finds duplicate or overlapping claims.

Walks all of a patient's claims and identifies:
1. Exact duplicate claims (same provider, date, CPT, amount)
2. Overlapping service lines (same CPT billed twice on the same DOS)
"""

import from graph.nodes.patient { Patient }
import from graph.nodes.claim { Claim }
import from graph.nodes.line_item { LineItem }
import from graph.nodes.dispute { Dispute }

import from datetime { datetime }
import from uuid { uuid4 }
import from collections { defaultdict }

walker DuplicateClaimDetector {

    can start with Patient entry {
        # Collect all claims and their line items for pairwise comparison
        claims = [c for c in [here-->] if isinstance(c, Claim)];

        # Build a map of (service_date, cpt_code, provider) → list of line items
        service_map = defaultdict(list);

        for claim in claims {
            line_items = [li for li in [claim-->] if isinstance(li, LineItem)];
            for item in line_items {
                key = f"{item.service_date}|{item.cpt_code}|{claim.claim_number[:4]}";
                service_map[key].append({
                    "claim_number": claim.claim_number,
                    "line_item": item,
                    "amount": item.charge_amount
                });
            }
        }

        # Flag any key with more than one entry as a potential duplicate
        for (key, entries) in service_map.items() {
            if len(entries) > 1 {
                parts = key.split("|");
                service_date = parts[0];
                cpt_code = parts[1];

                for i in range(1, len(entries)) {
                    dup_item = (entries[i]["line_item"] as LineItem);
                    total_dup_amount = sum(e["amount"] for e in entries[1:]);

                    dispute = Dispute(
                        dispute_id=str(uuid4()),
                        error_type="DUPLICATE_CHARGE",
                        description=(
                            f"CPT {cpt_code} appears to be billed {len(entries)} times "
                            f"on {service_date}. "
                            f"Potential duplicate on claims: "
                            f"{', '.join(e['claim_number'] for e in entries)}"
                        ),
                        amount_disputed=total_dup_amount,
                        expected_amount=entries[0]["amount"],
                        status="OPEN",
                        flagged_date=datetime.utcnow().isoformat(),
                        confidence_score=0.80,
                        severity="MEDIUM",
                        citations=["CMS Duplicate Claim Policy — same day, same provider, same service"]
                    );
                    dup_item ++> dispute;
                    dup_item.has_errors = True;
                    dup_item.error_count += 1;
                    print(
                        f"[DuplicateClaimDetector] Duplicate: {cpt_code} on {service_date} "
                        f"x{len(entries)} (${total_dup_amount:.2f} disputed)"
                    );
                }
            }
        }
    }
}
