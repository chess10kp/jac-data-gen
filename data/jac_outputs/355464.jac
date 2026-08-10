"""Computes x, y such that gcd(a,b) = ax + by"""
def egcd(a: int, b: int) -> tuple[int, int] {
    if not b {
        return (1, 0);
    }
    (x, y) = egcd(b, a % b);
    return (y, x - (a // b) * y);
}