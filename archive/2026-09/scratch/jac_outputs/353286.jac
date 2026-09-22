"""Average value of the cards in the hand."""
def card_average(hand: list[int]) -> float {
    total = 0;
    for card in hand {
        total += card;
    }
    return total / len(hand);
}