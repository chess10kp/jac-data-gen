"""Makes a list of word-freq pairs in descending order of frequency."""
def most_common(hist: dict[str, int]) -> list[tuple[int, str]] {
    t = [(value, key) for (key, value) in hist.items()];
    t.sort();
    t.reverse();
    return t;
}