"""Checks if two words can be pronounced the same way using a phonetic dictionary."""
def homophones(a: str, b: str, phonetic: dict[str, list[str]]) -> bool {
    if a not in phonetic or b not in phonetic {
        return False;
    }
    return phonetic[a] == phonetic[b];
}