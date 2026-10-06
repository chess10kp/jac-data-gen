"""SubscriptionAudit node — aggregated report of patient's subscription charges."""

node SubscriptionAudit {
    has audit_id: str = "",
        audit_date: str = "",
        total_monthly_spend: float = 0.0,
        total_annual_spend: float = 0.0,
        subscriptions_reviewed: int = 0,
        recommended_cancellations: list = [],   # list of subscription_ids
        estimated_monthly_savings: float = 0.0,
        estimated_annual_savings: float = 0.0,
        approval_status: str = "PENDING",       # PENDING | APPROVED | REJECTED
        approved_by: str = "",
        approved_date: str = "",
        summary_text: str = "",
        created_at: str = "";
}
