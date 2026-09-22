"""Check two values are equal and exit with message if not."""
def check_equal(val1: float, val2: float) -> bool {
    return abs(val1 - val2) < 1e-10;
}