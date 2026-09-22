"""Remove duplicate letters on either end, if the are adjacent."""
def chop_duplicate_ends(word: str) -> str {
    if word[0] == word[1] {
        word = word[1:];
    }
    if word[-2:-1] == word[-1:] {
        word = word[:-1];
    }
    return word;
}