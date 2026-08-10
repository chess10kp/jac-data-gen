"""
    Assumes that 'hand' has all the letters in word.
    In other words, this assumes that however many times
    a letter appears in 'word', 'hand' has at least as
    many of that letter in it.

    Updates the hand: uses up the letters in the given word
    and returns the new hand, without those letters in it.

    Has no side effects: does not modify hand.

    word: string
    hand: dictionary (string -> int)
    returns: dictionary (string -> int)
    """
def updateHand(hand: Any, word: Any) -> object {
    return {
        x: (hand[x] - word.count(x)) if (x in word) else hand[x]
        for x in hand
        if ((hand.get(x, 0) - word.count(x)) > 0)
    };
}