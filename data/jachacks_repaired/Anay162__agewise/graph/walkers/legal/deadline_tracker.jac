"""DeadlineTracker walker — tracks all legal and appeal deadlines across the graph."""

import from graph.nodes.patient { Patient }
import from graph.nodes.legal_document { LegalDocument }
import from graph.nodes.dispute { Dispute }
import from graph.nodes.appeal { Appeal }
import from graph.nodes.notification { Notification }

import from datetime { datetime, timedelta }
import from uuid { uuid4 }

glob WARN_DAYS = [7, 14, 30, 60];

walker DeadlineTracker {
    has today: any = None;
    has deadlines: list = [];

    can start with Patient entry {
        self.today = datetime.utcnow();
        self.deadlines = [];
        visit [-->];
    }

    can check_legal with LegalDocument entry {
        if here.expiry_date != "" {
            self._check_deadline(here.expiry_date, f"{here.doc_type} expiry", here, "LEGAL_EXPIRY");
        }
        visit [-->];
    }

    can check_dispute with Dispute entry {
        if here.deadline != "" {
            self._check_deadline(here.deadline, f"Appeal deadline (Level {here.appeal_level})", here, "APPEAL_DEADLINE");
        }
        visit [-->];
    }

    can check_appeal with Appeal entry {
        if here.due_date != "" {
            self._check_deadline(here.due_date, f"Appeal submission (Level {here.appeal_level})", here, "APPEAL_DEADLINE");
        }
    }

    def _check_deadline(date_str: str, label: str, nd: LegalDocument | Dispute | Appeal, notif_type: str) -> None {
        try {
            dt = datetime.strptime(date_str, "%Y-%m-%d");
            days = (dt - self.today).days;
            if days in WARN_DAYS or (days < 0 and days > -3) {
                severity = "CRITICAL" if days <= 7 else ("URGENT" if days <= 14 else "WARNING");
                msg = (f"{label}: {'OVERDUE by ' + str(abs(days)) + ' days' if days < 0 else str(days) + ' days remaining'} (due {date_str})");
                notif = Notification(
                    notification_id=str(uuid4()),
                    notification_type=notif_type,
                    severity=severity,
                    title=f"Deadline: {label}",
                    message=msg,
                    created_at=datetime.utcnow().isoformat()
                );
                (nd ++> notif);
                print(f"[DeadlineTracker] {msg}");
            }
        } except Exception as e {
            print(f"[DeadlineTracker] Date error for '{label}': {e}");
        }
    }
}
