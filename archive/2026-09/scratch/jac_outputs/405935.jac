"""Return True if two values are equal after converting to int."""
def equals(a: int | str | float | bool, b: int | str | float | bool) -> bool {
    (a, b) = (int(a), int(b));
    return a == b;
}