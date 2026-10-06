"""Transaction node — a financial transaction from Plaid.

Used for bill payment monitoring, scam detection, and subscription
identification.
"""

node Transaction {
    has plaid_transaction_id: str = "",
        amount: float = 0.0,            # positive = debit, negative = credit
        merchant_name: str = "",
        merchant_entity_id: str = "",
        date: str = "",
        posted_date: str = "",
        category: list[str] = [],       # Plaid categories
        category_id: str = "",
        payment_channel: str = "",      # online | in_store | other
        is_pending: bool = False,
        flagged: bool = False,
        flag_reason: str = "",
        # SCAM_SUSPECTED | ANOMALY | DUPLICATE | UNUSUAL_AMOUNT
        is_medical: bool = False,
        is_recurring: bool = False,
        recurring_group_id: str = "",
        created_at: str = "";
}
