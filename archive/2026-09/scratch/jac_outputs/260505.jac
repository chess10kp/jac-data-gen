"""Truncate a number to d decimal places."""
def truncate(x: float, d: int) -> float {
    if d > 0 {
        mult = 10.0 ** d;
        return int(x * mult) / mult;
    } else {
        mult = 10 ** -d;
        return int(x / mult) * mult;
    }
}