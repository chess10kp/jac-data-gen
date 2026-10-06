"""Subscription node — tracks digital/service subscriptions."""

node Subscription {
    has subscription_id: str = "",
        service_name: str = "",
        merchant_id: str = "",             # Normalized merchant identifier
        category: str = "",               # STREAMING | HEALTH | WELLNESS | NEWS | UTILITY | OTHER
        classification: str = "UNKNOWN",  # ESSENTIAL | USEFUL | WASTEFUL | UNKNOWN | CANCELLATION_QUEUED | CANCELLED
        monthly_cost: float = 0.0,
        annual_cost: float = 0.0,
        billing_cycle: str = "MONTHLY",
        next_billing_date: str = "",
        first_seen_date: str = "",        # Date first detected in transactions
        last_charge_date: str = "",       # Date of most recent charge
        start_date: str = "",
        cancellation_date: str = "",
        is_used: bool = True,             # Is the patient actually using this?
        usage_evidence: str = "",         # LLM-generated usage notes
        utility_score: float = 0.0,       # 0-1, estimated value to patient
        cancel_url: str = "",
        cancel_phone: str = "",
        status: str = "ACTIVE",
        notes: str = "",
        created_at: str = "";
}
