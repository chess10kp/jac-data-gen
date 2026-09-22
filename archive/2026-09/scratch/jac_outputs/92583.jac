"""Return a copy of string with occurrences of old replaced by new."""
def replace(s: str, old: str, new: str, maxsplit: int = 0) -> str {
    return s.replace(old, new, maxsplit);
}