"""RecurringBill node — detected recurring billing patterns."""

node RecurringBill {
    has bill_id: str = "",
        biller_name: str = "",
        biller_category: str = "",   # INSURANCE_PREMIUM | UTILITY | SUBSCRIPTION | etc.
        average_amount: float = 0.0,
        last_amount: float = 0.0,
        payment_frequency: str = "MONTHLY",  # WEEKLY | MONTHLY | QUARTERLY | ANNUAL
        typical_day_of_month: int = 1,
        last_payment_date: str = "",
        next_due_date: str = "",
        is_auto_pay: bool = False,
        account_last4: str = "",
        status: str = "ACTIVE",
        reminder_days_before: int = 5,
        transaction_count: int = 0,
        created_at: str = "";
}
