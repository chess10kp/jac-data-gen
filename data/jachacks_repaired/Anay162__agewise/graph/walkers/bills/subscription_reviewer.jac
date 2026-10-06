"""SubscriptionReviewer walker — identifies unused/duplicate subscriptions to cancel."""

import from graph.nodes.patient { Patient }
import from graph.nodes.subscription { Subscription }
import from graph.nodes.notification { Notification }
import from abilities.llm_abilities { assess_subscription_utility }

import from datetime { datetime }
import from uuid { uuid4 }

glob REVIEW_AGE_DAYS: int = 90;  # Flag subscriptions unused for 90+ days

walker SubscriptionReviewer {
    has patient_name: str = "";
    has flagged: int = 0;


    can start with Patient entry {
        self.patient_name = here.name;
        self.flagged = 0;
        visit [-->];
    }

    can review with Subscription entry {
        if here.status != "ACTIVE" {
            disengage;
        }

        should_flag = False;
        reason = "";

        # Check if unused
        if not here.is_used and here.monthly_cost > 0 {
            should_flag = True;
            reason = f"Subscription '{here.service_name}' (${here.monthly_cost:.2f}/mo) may be unused.";
        }

        # Low utility score
        if here.utility_score < 0.2 and here.monthly_cost > 5.0 {
            should_flag = True;
            reason = f"Subscription '{here.service_name}' has low utility score ({here.utility_score:.1f}).";
        }

        if should_flag {
            notif = Notification(
                notification_id=str(uuid4()),
                notification_type="ACTION_REQUIRED",
                severity="LOW",
                title=f"Review Subscription: {here.service_name}",
                message=f"{reason} Consider cancelling at: {here.cancel_url or here.cancel_phone or 'contact provider'}.",
                created_at=datetime.utcnow().isoformat()
            );
            here ++> notif;
            self.flagged += 1;
            print(f"[SubscriptionReviewer] Flagged: {here.service_name} (${here.monthly_cost:.2f}/mo)");
        }
    }

    can finish with Patient entry {
        if self.flagged > 0 {
            print(f"[SubscriptionReviewer] {self.flagged} subscription(s) flagged for review for {self.patient_name}");
        }
        report {"patient": self.patient_name, "flagged_subscriptions": self.flagged};
    }
}
