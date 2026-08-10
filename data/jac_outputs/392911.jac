"""return (g, x, y) such that a*x + b*y = g = gcd(a, b)"""
def pulverizer(a: int, b: int) -> tuple[int, int, int] {
    (x0, x1, y0, y1) = (0, 1, 1, 0);
    while a != 0 {
        (q, b, a) = (b // a, a, b % a);
        (y0, y1) = (y1, y0 - q * y1);
        (x0, x1) = (x1, x0 - q * x1);
    }
    return (b, x0, y0);
}