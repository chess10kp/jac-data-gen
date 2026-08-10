"""
    Division in integers modulus p means finding the inverse of the
    denominator modulo p and then multiplying the numerator by this
    inverse (Note: inverse of A is B such that A*B % p == 1) this can
    be computed via extended Euclidean algorithm
    http://en.wikipedia.org/wiki/Modular_multiplicative_inverse#Computation
"""
def _extended_gcd(a: int, b: int) -> tuple[int, int] {
    x = 0;
    last_x = 1;
    y = 1;
    last_y = 0;
    while b != 0 {
        quot = a // b;
        (a, b) = (b, a % b);
        (x, last_x) = (last_x - quot * x, x);
        (y, last_y) = (last_y - quot * y, y);
    }
    return (last_x, last_y);
}