"""Filter bank loans to those whose minimum credit score requirement is met."""
def filter_credit_score(credit_score: int, bank_list: list[list[str | int | float]]) -> list[list[str | int | float]] {
    return [bank for bank in bank_list if credit_score >= int(bank[4])];
}