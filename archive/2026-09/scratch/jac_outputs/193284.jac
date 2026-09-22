"""Truncate text to a maximum number of characters."""
def truncate(s: str, maxlen: int = 128, suffix: str = '...') -> str {
    if maxlen and len(s) >= maxlen {
        return s[:maxlen].rsplit(' ', 1)[0] + suffix;
    }
    return s;
}