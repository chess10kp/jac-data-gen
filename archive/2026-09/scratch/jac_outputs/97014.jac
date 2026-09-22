"""Return number of leading whitespace characters."""
def _wlen(s: str) -> int {
    len(s) - len(s.lstrip())
}