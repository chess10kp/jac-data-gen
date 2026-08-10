"""Account sends transactions with combined total value >= threshold within a day."""
def business_rule_3(amount: int, account: int, use_br: bool, threshold: int) -> bool {
    if not use_br {
        return True;
    }
    return amount * (account - 2) < threshold;
}