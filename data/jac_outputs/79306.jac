"""Scores a word relative to another word by matching letters in position."""
def score_word(a: str, b: str) -> int {
    return sum(a[i] == b[i] for i in range(len(a)));
}