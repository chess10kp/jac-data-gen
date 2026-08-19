enum Suit {
    HEARTS = "HEARTS",
    DIAMONDS = "DIAMONDS",
    CLUBS = "CLUBS",
    SPADES = "SPADES"
}

def color(s: Suit) -> str {
    if s == Suit.HEARTS or s == Suit.DIAMONDS { return "red"; }
    return "black";
}

with entry {
    print(color(Suit.HEARTS));
}
