"""ExpiryMonitor walker — flags legal documents approaching expiry."""

import from graph.nodes.patient { Patient }
import from graph.nodes.legal_document { LegalDocument }
import from graph.nodes.notification { Notification }

import from datetime { datetime, timedelta }
import from uuid { uuid4 }

glob EXPIRY_WARNING_DAYS = 90;

walker ExpiryMonitor {

    can start with Patient entry {
        visit [-->];
    }

    can check_doc with LegalDocument entry {
        if here.expiry_date == "" or here.status == "EXPIRED" {
            disengage;
        }

        try {
            expiry = datetime.strptime(here.expiry_date, "%Y-%m-%d");
            today = datetime.utcnow();
            days_left = (expiry - today).days;
            here.days_until_expiry = days_left;

            if days_left < 0 {
                here.status = "EXPIRED";
                notif = Notification(
                    notification_id=str(uuid4()),
                    notification_type="LEGAL_EXPIRY",
                    severity="URGENT",
                    title=f"{here.doc_type} Expired",
                    message=f"{here.doc_type} expired on {here.expiry_date}. Renewal required.",
                    created_at=datetime.utcnow().isoformat()
                );
                here ++> notif;
                print(f"[ExpiryMonitor] EXPIRED: {here.doc_type} {here.legal_doc_id}");
            } elif days_left <= EXPIRY_WARNING_DAYS {
                severity = "URGENT" if days_left <= 30 else "WARNING";
                notif = Notification(
                    notification_id=str(uuid4()),
                    notification_type="LEGAL_EXPIRY",
                    severity=severity,
                    title=f"{here.doc_type} Expiring in {days_left} Days",
                    message=f"{here.doc_type} expires on {here.expiry_date}. Review and renew.",
                    created_at=datetime.utcnow().isoformat()
                );
                here ++> notif;
                print(f"[ExpiryMonitor] Expiry warning: {here.doc_type} in {days_left} days");
            }
        } except Exception as e {
            print(f"[ExpiryMonitor] Date parse error for {here.legal_doc_id}: {e}");
        }
    }
}
