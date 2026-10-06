"""SubscriptionIdentifier walker — identifies recurring charges and creates subscription nodes."""

import from graph.nodes.patient { Patient }
import from graph.nodes.transaction { Transaction }
import from graph.nodes.financial_account { FinancialAccount }
import from graph.nodes.subscription { Subscription }
import from datetime { datetime }
import from uuid { uuid4 }

walker SubscriptionIdentifier {
    has subscriptions_found: int = 0,
        min_occurrences: int = 2;

    can identify with Patient entry {
        merchant_charges: dict = {};
        existing_subs = {n.merchant_id for n in [here-->] if isinstance(n, Subscription)};

        for acct in [here-->] {
            if not isinstance(acct, FinancialAccount) {
                continue;
            }
            for txn in [acct-->] {
                if not isinstance(txn, Transaction) or txn.amount >= 0 {
                    continue;
                }
                key = txn.merchant_name.strip().lower();
                if key not in merchant_charges {
                    merchant_charges[key] = [];
                }
                merchant_charges[key].append({"date": txn.date, "amount": abs(txn.amount)});
            }
        }

        for (merchant, charges) in merchant_charges.items() {
            if len(charges) < self.min_occurrences {
                continue;
            }
            merchant_id = merchant.replace(" ", "_")[:32];
            if merchant_id in existing_subs {
                continue;
            }
            avg_cost = sum(c["amount"] for c in charges) / len(charges);
            sub = Subscription(
                subscription_id=str(uuid4()),
                service_name=merchant.title(),
                merchant_id=merchant_id,
                monthly_cost=avg_cost,
                annual_cost=avg_cost * 12,
                classification="UNKNOWN",
                first_seen_date=min(c["date"] for c in charges),
                last_charge_date=max(c["date"] for c in charges),
                created_at=datetime.utcnow().isoformat()
            );
            here ++> sub;
            existing_subs.add(merchant_id);
            self.subscriptions_found += 1;
        }

        report {"patient": here.name, "subscriptions_found": self.subscriptions_found};
    }
}
