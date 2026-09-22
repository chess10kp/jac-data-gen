"""Return str(n) unless n is zero, in which case return ""."""
def blank_if_zero(n: int) -> str {
    return "" if n == 0 else str(n);
}