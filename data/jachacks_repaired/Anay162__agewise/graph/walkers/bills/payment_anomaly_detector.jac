"""PaymentAnomalyDetector walker — flags unusual payment amounts or unexpected billers."""

import from graph.nodes.patient { Patient }
import from graph.nodes.recurring_bill { RecurringBill }
import from graph.nodes.transaction { Transaction }
import from graph.nodes.financial_account { FinancialAccount }
import from graph.nodes.scam_alert { ScamAlert }
import from abilities.notification_sender { send_notification }
import from datetime { datetime }
import from uuid { uuid4 }

walker PaymentAnomalyDetector {
    has anomalies_found: int = 0,
        threshold_multiplier: float = 2.0;

    can detect with Patient entry {
        bills = [n for n in [here-->] if isinstance(n, RecurringBill)];
        bill_map: dict = {b.biller_name.lower(): b.average_amount for b in bills};

        for acct in [here-->] {
            if not isinstance(acct, FinancialAccount) {
                continue;
            }
            for txn in [acct-->] {
                if not isinstance(txn, Transaction) or txn.amount >= 0 {
                    continue;
                }
                amt = abs(txn.amount);
                merchant_lower = txn.merchant_name.lower();
                matched_biller = None;
                for biller in bill_map {
                    if biller in merchant_lower {
                        matched_biller = biller;
                        break;
                    }
                }
                if matched_biller {
                    expected = bill_map[matched_biller];
                    if expected > 0 and amt > expected * self.threshold_multiplier {
                        self.anomalies_found += 1;
                        alert = ScamAlert(
                            alert_id=str(uuid4()),
                            threat_type="PAYMENT_ANOMALY",
                            description=f"Unusual charge: {txn.merchant_name} charged ${amt:.2f} (expected ~${expected:.2f})",
                            confidence_score=0.8,
                            detected_at=datetime.utcnow().isoformat()
                        );
                        root ++> alert;
                    }
                }
            }
        }

        report {"patient": here.name, "anomalies_found": self.anomalies_found};
    }
}
