"""paid_from edge — RecurringBill paid from a PaymentAccount."""

edge paid_from {
    has autopay_setup_date: str = "",
        payment_method: str = "";   # ACH | CREDIT | DEBIT | CHECK
}
