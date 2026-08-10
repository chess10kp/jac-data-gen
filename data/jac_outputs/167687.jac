"""Return a list of all possible (first, rest) pairs, len(first)<=L."""
def splits(text: str, L: int = 20) -> list[tuple[str, str]] {
    return [(text[:(i + 1)], text[(i + 1):]) for i in range(min(len(text), L))];
}