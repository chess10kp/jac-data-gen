"""Compute x / y, but return 0 if y is zero."""
def safe_divide(x: int | float, y: int | float) -> int | float {
    if y == 0 {
        return 0;
    }
    return x / y;
}