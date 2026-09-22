"""
Stub card generator monkeypatched into the flight module for testing
boarding card printing.
"""
def text_card_generator(card_details: dict[str, str]) -> str {
    return "\n".join(card_details.values());
}