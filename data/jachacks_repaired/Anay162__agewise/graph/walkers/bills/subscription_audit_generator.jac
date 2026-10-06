"""SubscriptionAuditGenerator walker — generates subscription audit report with savings estimates."""

import from graph.nodes.patient { Patient }
import from graph.nodes.subscription { Subscription }
import from graph.nodes.subscription_audit { SubscriptionAudit }
import from abilities.llm_abilities { generate_subscription_audit_summary }
import from datetime { datetime }
import from uuid { uuid4 }

walker SubscriptionAuditGenerator {
    can generate with Patient entry {
        subs = [n for n in [here-->] if isinstance(n, Subscription)];
        wasteful = [s for s in subs if s.classification == "WASTEFUL"];
        total_monthly = sum(s.monthly_cost for s in subs);
        potential_savings = sum(s.monthly_cost for s in wasteful);

        summary = generate_subscription_audit_summary(
            patient_name=here.name,
            subscriptions=[{"name": s.service_name, "cost": s.monthly_cost, "class": s.classification} for s in subs],
            potential_savings=potential_savings
        );

        audit = SubscriptionAudit(
            audit_id=str(uuid4()),
            audit_date=datetime.utcnow().isoformat()[:10],
            total_monthly_spend=total_monthly,
            total_annual_spend=total_monthly * 12,
            subscriptions_reviewed=len(subs),
            recommended_cancellations=[s.subscription_id for s in wasteful],
            estimated_monthly_savings=potential_savings,
            estimated_annual_savings=potential_savings * 12,
            approval_status="PENDING",
            summary_text=summary.get("text", ""),
            created_at=datetime.utcnow().isoformat()
        );
        here ++> audit;

        report {
            "patient": here.name,
            "total_monthly_spend": total_monthly,
            "potential_monthly_savings": potential_savings
        };
    }
}
