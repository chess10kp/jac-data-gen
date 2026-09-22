"""Return list of (start, end , [list of subtokens]) for each token."""
def partition_subtokens(subtokens: list[str]) -> list[tuple[int, int, list[str]]] {
    words = [];
    last = 0;
    for (i, token) in enumerate(subtokens) {
        if token[-1] == '_' {
            words.append((last, i + 1, subtokens[last:(i + 1)]));
            last = i + 1;
        }
    }
    return words;
}