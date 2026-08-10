"""Return set of symbol pairs in a word."""
def get_pairs(word: tuple[str, ...]) -> set[tuple[str, str]] {
    pairs = set();
    prev_char = word[0];
    for char in word[1:] {
        pairs.add((prev_char, char));
        prev_char = char;
    }
    return pairs;
}