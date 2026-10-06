"""MissedPaymentDetector walker — detects missed payments and late fees from transactions."""

import from graph.nodes.patient { Patient }
import from graph.nodes.recurring_bill { RecurringBill }
import from graph.nodes.transaction { Transaction }
import from graph.nodes.financial_account { FinancialAccount }
import from abilities.notification_sender { send_notification }
import from datetime { datetime }

walker MissedPaymentDetector {
    has missed_count: int = 0;

    can detect with Patient entry {
        bills = [n for n in [here-->] if isinstance(n, RecurringBill)];
        today = datetime.utcnow().isoformat()[:10];

        for bill in bills {
            if not bill.next_due_date or bill.next_due_date > today {
                continue;
            }
            # Check if a matching payment exists in transaction history
            found_payment = False;
            for acct in [here-->] {
                if not isinstance(acct, FinancialAccount) {
                    continue;
                }
                for txn in [acct-->] {
                    if not isinstance(txn, Transaction) {
                        continue;
                    }
                    if bill.biller_name.lower() in txn.merchant_name.lower() {
                        if txn.date >= bill.last_payment_date {
                            found_payment = True;
                            break;
                        }
                    }
                }
                if found_payment {
                    break;
                }
            }
            if not found_payment {
                self.missed_count += 1;
                send_notification(
                    patient_id=here.name,
                    channel="SMS",
                    message=f"Missed payment alert: {bill.biller_name} was due {bill.next_due_date}.",
                    severity="HIGH"
                );
            }
        }
        report {"patient": here.name, "missed_payments": self.missed_count};
    }
}
