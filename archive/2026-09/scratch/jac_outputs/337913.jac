"""Deposit given amount of money to the account."""
def deposit_money(amount: int, card_balance: int) -> int {
    card_balance += amount;
    return card_balance;
}