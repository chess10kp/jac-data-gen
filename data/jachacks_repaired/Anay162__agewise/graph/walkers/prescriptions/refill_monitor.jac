"""RefillMonitor walker — flags prescriptions approaching or past their refill date.

Walks Patient -> Prescription nodes, computes days until refill based on
fill_date + days_supply, and creates Notification nodes for anything due
within 7 days or already overdue.
"""

import from graph.nodes.patient { Patient }
import from graph.nodes.prescription { Prescription }
import from graph.nodes.medication { Medication }
import from graph.nodes.notification { Notification }

import from datetime { datetime, timedelta }
import from uuid { uuid4 }

glob WARN_DAYS: int = 7;   # Alert when refill is due within this many days
glob URGENT_DAYS: int = 0; # Alert as URGENT when at or past due date


"""Returns days until refill is due. Negative = overdue."""
def _days_until_refill(fill_date: str, days_supply: int) -> int {
    if not fill_date {
        return 999;
    }
    try {
        filled_dt = datetime.strptime(fill_date, "%Y-%m-%d");
        refill_due = filled_dt + timedelta(days=days_supply);
        return (refill_due - datetime.utcnow()).days;
    } except Exception {
        return 999;
    }
}


"""Creates notifications for prescriptions due for refill soon or overdue."""
walker RefillMonitor {

    has overdue_count: int = 0,
        due_soon_count: int = 0;

    can start with Patient entry {
        prescriptions = [n for n in [here-->] if isinstance(n, Prescription) and n.status == "ACTIVE"];

        # Also check Medication nodes (in case MedicationListBuilder ran first)
        medications = [n for n in [here-->] if isinstance(n, Medication) and n.active];

        checked = set();

        for rx in prescriptions {
            key = (rx.generic_name or rx.drug_name or rx.prescription_id).lower();
            if key in checked {
                continue;
            }
            checked.add(key);

            days_left = _days_until_refill(rx.fill_date, rx.days_supply);

            if days_left > WARN_DAYS {
                continue;
            }

            drug_label = rx.drug_name or rx.generic_name or "medication";

            if days_left < 0 {
                severity = "HIGH";
                title = f"Refill Overdue: {drug_label}";
                message = (
                    f"{drug_label} ({rx.dosage}) was due for refill {abs(days_left)} day(s) ago. "
                    f"Refills remaining: {rx.refills_remaining}. "
                    f"Pharmacy: {rx.pharmacy_name or 'on file'}."
                );
                self.overdue_count += 1;
            } else {
                severity = "MEDIUM";
                title = f"Refill Due Soon: {drug_label}";
                message = (
                    f"{drug_label} ({rx.dosage}) is due for refill in {days_left} day(s). "
                    f"Refills remaining: {rx.refills_remaining}. "
                    f"Pharmacy: {rx.pharmacy_name or 'on file'}."
                );
                self.due_soon_count += 1;
            }

            notif = Notification(
                notification_id=str(uuid4()),
                notification_type="REFILL_REMINDER",
                severity=severity,
                title=title,
                message=message,
                reference_id=rx.prescription_id,
                created_at=datetime.utcnow().isoformat(),
                delivered_at="",
                read_at=""
            );
            here ++> notif;
            print(f"[RefillMonitor] {title} (days_left={days_left})");
        }

        report {
            "patient": here.name,
            "overdue": self.overdue_count,
            "due_soon": self.due_soon_count
        };
    }
}
