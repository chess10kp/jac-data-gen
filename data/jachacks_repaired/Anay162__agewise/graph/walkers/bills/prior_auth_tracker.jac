"""PriorAuthTracker walker — tracks expiring prior authorizations and denied auths."""

import from graph.nodes.patient { Patient }
import from graph.nodes.prior_auth { PriorAuth }
import from graph.nodes.notification { Notification }

import from datetime { datetime, timedelta }
import from uuid { uuid4 }

glob EXPIRY_WARN_DAYS: int = 14;

walker PriorAuthTracker {
    has today: any = None;
    has alerts: int = 0;


    can start with Patient entry {
        self.today = datetime.utcnow();
        self.alerts = 0;
        visit [-->];
    }

    can track with PriorAuth entry {
        if here.status == "EXPIRED" or here.status == "WITHDRAWN" {
            disengage;
        }

        # Check for expiring approved auths
        if here.status == "APPROVED" and here.expiry_date != "" {
            try {
                expiry = datetime.strptime(here.expiry_date, "%Y-%m-%d");
                days_left = (expiry - self.today).days;
                if 0 <= days_left <= EXPIRY_WARN_DAYS {
                    notif = Notification(
                        notification_id=str(uuid4()),
                        notification_type="ACTION_REQUIRED",
                        severity="URGENT" if days_left <= 7 else "WARNING",
                        title=f"Prior Auth Expiring: {here.service_requested}",
                        message=(
                            f"Prior authorization #{here.auth_number} for {here.service_requested} "
                            f"expires in {days_left} day(s) on {here.expiry_date}. "
                            f"Contact {here.requesting_provider} to renew if still needed."
                        ),
                        created_at=datetime.utcnow().isoformat()
                    );
                    here ++> notif;
                    self.alerts += 1;
                    print(f"[PriorAuthTracker] Auth expiring in {days_left} days: {here.auth_number}");
                }
            } except Exception as e {
                print(f"[PriorAuthTracker] Date error: {e}");
            }
        }

        # Check for denied auths still within appeal window
        if here.status == "DENIED" and here.appeal_deadline != "" {
            try {
                deadline = datetime.strptime(here.appeal_deadline, "%Y-%m-%d");
                days_left = (deadline - self.today).days;
                if 0 < days_left <= 30 {
                    notif = Notification(
                        notification_id=str(uuid4()),
                        notification_type="APPEAL_DEADLINE",
                        severity="URGENT" if days_left <= 7 else "WARNING",
                        title=f"Prior Auth Appeal Deadline: {here.service_requested}",
                        message=(
                            f"Prior authorization for {here.service_requested} was denied by {here.insurer_name}. "
                            f"Appeal deadline: {here.appeal_deadline} ({days_left} days). "
                            f"Reason: {here.denial_reason}"
                        ),
                        created_at=datetime.utcnow().isoformat()
                    );
                    here ++> notif;
                    self.alerts += 1;
                    print(f"[PriorAuthTracker] Appeal window closing: {here.auth_number}");
                }
            } except Exception as e {
                print(f"[PriorAuthTracker] Date error: {e}");
            }
        }
    }

    can finish with Patient entry {
        report {"alerts_generated": self.alerts};
    }
}
