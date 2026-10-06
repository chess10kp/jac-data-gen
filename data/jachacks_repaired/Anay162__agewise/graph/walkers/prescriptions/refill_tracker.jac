"""RefillTracker walker — monitors active prescriptions and flags overdue refills."""

import from graph.nodes.patient { Patient }
import from graph.nodes.prescription { Prescription }
import from abilities.notification_sender { send_notification }
import from datetime { datetime }

walker RefillTracker {
    has overdue_count: int = 0,
        due_soon_count: int = 0,
        days_warning: int = 7;

    can track with Patient entry {
        today = datetime.utcnow().isoformat()[:10];

        for med in [here-->] {
            for rx in [med-->] {
                if not isinstance(rx, Prescription) {
                    continue;
                }
                if rx.refills_remaining <= 0 or not rx.is_active {
                    continue;
                }
                if rx.next_fill_due and rx.next_fill_due < today {
                    self.overdue_count += 1;
                    send_notification(
                        patient_id=here.name,
                        channel="SMS",
                        message=f"Refill overdue: {rx.drug_name}. Last filled: {rx.last_fill_date}.",
                        severity="HIGH"
                    );
                }
            }
        }

        report {
            "patient": here.name,
            "overdue_refills": self.overdue_count,
            "due_soon": self.due_soon_count
        };
    }
}
