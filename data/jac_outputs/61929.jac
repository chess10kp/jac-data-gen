"""Truncates a string after a certain number of characters."""
def cutoff(s: str, length: int) -> str {
    if len(s) < length - 2 {
        return s;
    }
    return "%s.." % s[0:length - 2];
}