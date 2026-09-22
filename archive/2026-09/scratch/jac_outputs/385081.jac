"""Vector Subtraction function."""
def vector(b: list[int | float], e: list[int | float]) -> tuple[int | float, int | float, int | float] {
    (x, y, z) = b;
    (X, Y, Z) = e;
    return (X - x, Y - y, Z - z);
}