"""Solve a*x + b*y = gcd(a, b)."""
def exgcd(a: int, b: int) -> tuple[int, int, int] {
    if a == 0 {
        return (b, 0, 1);
    }
    (g, y, x) = exgcd(b % a, a);
    return (g, x - (b // a) * y, y);
}