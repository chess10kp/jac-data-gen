"""Remove from 's' any unicode characters, including emoji."""
def remove_unicode(s: str) -> str {
    return s.encode("ascii", "ignore").decode();
}