"""PaymentAccount node — payment method on file for bill payment tracking."""

node PaymentAccount {
    has account_id: str = "",
        account_type: str = "CHECKING",  # CHECKING | SAVINGS | CREDIT_CARD
        bank_name: str = "",
        last4: str = "",
        routing_last4: str = "",
        is_primary: bool = False,
        plaid_account_id: str = "",   # Reference to FinancialAccount node
        auto_pay_billers: list[str] = [],
        monthly_withdrawal_limit: float = 0.0,
        status: str = "ACTIVE",
        added_date: str = "";
}
