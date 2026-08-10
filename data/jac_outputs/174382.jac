"""Implement an algorithm to determine if a string has all unique characters."""
def has_unique_chars(string: str | None) -> bool {
    if string is None {
        return False;
    }
    if not isinstance(string, str) {
        return False;
    }
    return len(set(string)) == len(string);
}