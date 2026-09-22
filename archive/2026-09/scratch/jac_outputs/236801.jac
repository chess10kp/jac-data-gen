"""Return True if there are no high cards in list_name, False otherwise."""
def no_high(list_name: list[str]) -> bool {
    return not any(card in list_name for card in ("jack", "queen", "king", "ace"));
}