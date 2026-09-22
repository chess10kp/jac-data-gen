"""Divides two floats where the second must be non-zero."""
def divide(x: float, y: float) -> float {
    if y != 0 {
        return x / y;
    } else {
        raise ZeroDivisionError;
    }
}