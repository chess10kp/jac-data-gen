"""Return the secret number hidden by isMyNumber."""
def jumpAndBackpedal(isMyNumber: callable) -> int {
    guess = 0;
    if isMyNumber(guess) == 0 {
        return guess;
    }
    foundNumber = False;
    while not foundNumber {
        if isMyNumber(guess) == 1 {
            guess = guess - 1;
        } elif isMyNumber(guess) == -1 {
            guess = guess + 1;
        } else {
            foundNumber = True;
        }
    }
    return guess;
}