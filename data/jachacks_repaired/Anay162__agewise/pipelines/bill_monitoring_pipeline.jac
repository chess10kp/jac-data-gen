"""BillMonitoringPipeline — full flow: detect recurring bills → track due dates → flag missed → alert."""

import from graph.nodes.patient { Patient }
import from graph.walkers.bills.recurring_bill_detector { RecurringBillDetector }
import from graph.walkers.bills.bill_due_date_tracker { BillDueDateTracker }
import from graph.walkers.bills.missed_payment_detector { MissedPaymentDetector }
import from graph.walkers.bills.payment_anomaly_detector { PaymentAnomalyDetector }
import from graph.walkers.bills.subscription_identifier { SubscriptionIdentifier }
import from graph.walkers.bills.subscription_classifier { SubscriptionClassifier }
import from graph.walkers.bills.subscription_audit_generator { SubscriptionAuditGenerator }

walker BillMonitoringPipeline {
    can run with Patient entry {
        here spawn RecurringBillDetector();
        here spawn BillDueDateTracker();
        here spawn MissedPaymentDetector();
        here spawn PaymentAnomalyDetector();
        here spawn SubscriptionIdentifier();
        here spawn SubscriptionClassifier();
        here spawn SubscriptionAuditGenerator();
        report {"pipeline": "bill_monitoring", "patient": here.name, "status": "complete"};
    }
}
