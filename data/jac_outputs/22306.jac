"""Calculates GCD iteratively, using Euclid's algorithm."""
def egcd(b: int, n: int) -> tuple[int, int, int] {
    (x0, x1, y0, y1) = (1, 0, 0, 1);
    while n != 0 {
        (q, b, n) = (b // n, n, b % n);
        (x0, x1) = (x1, x0 - q * x1);
        (y0, y1) = (y1, y0 - q * y1);
    }
    return (b, x0, y0);
}