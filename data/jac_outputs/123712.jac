"""Checks if the colour/value matches the card in the players hand."""
def card_matches(card: list[str], hand: list[list[str]]) -> bool {
    wilds = ["wild", "wild+4"];
    for player_card in hand {
        if player_card[0] in wilds {
            return True;
        }
        if card[0] in wilds and player_card[0] == card[1] {
            return True;
        }
        if player_card[0] == card[0] or player_card[1] == card[1] {
            return True;
        }
    }
    return False;
}