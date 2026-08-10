"""Determine whether x is between X1 and X2."""
def is_between(low: float, x: float, high: float) -> bool {
    return low <= x and x <= high;
}