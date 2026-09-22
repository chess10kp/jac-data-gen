"""
        Sort transactions by amount of dollars.
    """
def _sort_by_amount(transactions: list) -> list {
    sorted_transactions = sorted(
        transactions,
        key=lambda (transaction: Any) { transaction["amount"]; },
        reverse=True
    );
    return sorted_transactions;
}