"""Returns index of letter in alphabet e.g. A -> 1, B -> 2, ..."""
def score(letter: str) -> int {
    return 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.index(letter) + 1;
}