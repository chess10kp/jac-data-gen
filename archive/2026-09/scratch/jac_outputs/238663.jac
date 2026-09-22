"""Splits the given string s and returns a hash mapping the words to their
    word position in the string"""
def reverse_hashify(s: str) -> dict[str, int] {
    d = {};
    for (i, word) in enumerate(s.split()) {
        d[word] = i;
    }
    return d;
}