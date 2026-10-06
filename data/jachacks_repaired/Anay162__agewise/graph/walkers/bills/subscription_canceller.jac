"""SubscriptionCanceller walker — dispatches voice agent to cancel approved cancellations."""

import from graph.nodes.patient { Patient }
import from graph.nodes.subscription { Subscription }
import from graph.nodes.subscription_audit { SubscriptionAudit }
import from graph.nodes.phone_call { PhoneCall }
import from datetime { datetime }
import from uuid { uuid4 }

walker SubscriptionCanceller {
    has calls_queued: int = 0;

    can cancel with Patient entry {
        approved_audits = [
            n for n in [here-->]
            if isinstance(n, SubscriptionAudit) and n.approval_status == "APPROVED"
        ];
        if not approved_audits {
            report {"calls_queued": 0};
            return;
        }

        to_cancel_ids: set = set();
        for audit in approved_audits {
            for sid in audit.recommended_cancellations {
                to_cancel_ids.add(sid);
            }
        }

        for sub in [here-->] {
            if not isinstance(sub, Subscription) {
                continue;
            }
            if sub.subscription_id in to_cancel_ids and sub.classification == "WASTEFUL" {
                call = PhoneCall(
                    call_id=str(uuid4()),
                    call_type="SUBSCRIPTION_CANCELLATION",
                    target_name=sub.service_name,
                    purpose=f"Cancel subscription: {sub.service_name} (${sub.monthly_cost:.2f}/mo) for {here.name}",
                    status="QUEUED",
                    created_at=datetime.utcnow().isoformat()
                );
                root ++> call;
                sub.classification = "CANCELLATION_QUEUED";
                self.calls_queued += 1;
            }
        }

        report {"patient": here.name, "cancellations_queued": self.calls_queued};
    }
}
