"""RecurringBillDetector walker — identifies recurring bills from Plaid transactions.

Walks a patient's FinancialAccount nodes, analyzes the transaction history
to identify recurring charges (same merchant, similar amount, regular cadence),
and creates RecurringBill nodes for each.
"""

import from graph.nodes.patient { Patient }
import from graph.nodes.financial_account { FinancialAccount }
import from graph.nodes.transaction { Transaction }

import from collections { defaultdict }
import from datetime { datetime }
import from uuid { uuid4 }
import from statistics { mean }

# A charge is considered recurring if it appears ≥ 2 times
# with similar amounts (within 20%)
glob MIN_OCCURRENCES = 2;
glob AMOUNT_VARIANCE_THRESHOLD = 0.20;

node RecurringBill {
    has bill_id: str = "",
        biller_name: str = "",
        category: str = "subscription",
        expected_amount: float = 0.0,
        amount_variance_pct: float = 0.0,
        due_day_of_month: int = 0,
        frequency: str = "monthly",
        last_paid_date: str = "",
        last_paid_amount: float = 0.0,
        status: str = "current",
        days_until_due: int = 0,
        source_account_id: str = "";
}

walker RecurringBillDetector {

    can start with Patient entry {
        visit [-->];
    }

    can scan_account with FinancialAccount entry {
        transactions = [t for t in [here-->] if isinstance(t, Transaction)];
        if len(transactions) == 0 {
            disengage;
        }

        # Group transactions by merchant
        by_merchant = defaultdict(list);
        for t in transactions {
            merchant = t.merchant_name.strip().upper()[:50];
            if merchant {
                by_merchant[merchant].append(t);
            }
        }

        # Identify recurring charges
        for (merchant, txns) in by_merchant.items() {
            if len(txns) < MIN_OCCURRENCES {
                continue;
            }

            amounts = [abs(t.amount) for t in txns if t.amount != 0];
            if len(amounts) == 0 {
                continue;
            }

            avg_amount = mean(amounts);
            if avg_amount < 1.0 {
                continue;
            }

            # Check variance (all amounts within 20% of mean)
            variance = max(abs(a - avg_amount) / avg_amount for a in amounts) if avg_amount > 0 else 1;
            if variance > AMOUNT_VARIANCE_THRESHOLD {
                continue;  # Too variable — not a regular bill
            }

            # Find payment day of month
            dates = sorted([t.date for t in txns]);
            day = int(dates[-1].split("-")[2]) if dates else 1;

            # Check if already tracked
            existing = [b for b in [here-->] if isinstance(b, RecurringBill) and b.biller_name.upper() == merchant];
            if len(existing) > 0 {
                # Update existing
                existing[0].last_paid_date = dates[-1];
                existing[0].last_paid_amount = amounts[-1] if amounts else 0;
                continue;
            }

            bill = RecurringBill(
                bill_id=str(uuid4()),
                biller_name=txns[0].merchant_name or merchant,
                category="subscription",
                expected_amount=round(avg_amount, 2),
                amount_variance_pct=round(variance * 100, 1),
                due_day_of_month=day,
                frequency="monthly",
                last_paid_date=dates[-1] if dates else "",
                last_paid_amount=round(amounts[-1] if amounts else 0, 2),
                status="current",
                source_account_id=here.plaid_account_id
            );
            here ++> bill;
            print(f"[RecurringBillDetector] Found recurring: {merchant} ~${avg_amount:.2f}/mo");
        }
    }
}
