"""Escape a Birdiescript string."""
def escape_birdiescript(s: str) -> str {
    return s.replace('\\', '\\\\').replace('`', '\\`');
}