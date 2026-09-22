"""Compute gcd of two positive integers x and y"""
def compute_gcd(x: int, y: int) -> int {
    if x < y {
        return compute_gcd(y, x);
    }
    residual = x % y;
    if residual == 0 {
        return y;
    }
    if residual == 1 {
        return 1;
    }
    return compute_gcd(y, residual);
}