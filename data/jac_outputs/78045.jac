"""Count the number of remaining cards in the deck."""
def count_deck(deck: dict[str, dict[str, int]]) -> int {
    total = 0;
    for (card, card_item) in deck.items() {
        total += card_item['count'];
    }
    return total;
}