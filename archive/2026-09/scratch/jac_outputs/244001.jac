"""Get sign of the given number."""
def _sign(number: int) -> int {
    if number > 0 {
        return 1;
    }
    if number < 0 {
        return -1;
    }
    return 0;
}