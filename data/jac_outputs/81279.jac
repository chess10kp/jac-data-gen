"""
    Computes greatest common divisor (gcd) and coefficients of Bezout's identity
    for provided integers `a` and `b` using extended Euclidean Algorithm.

    Args:
        a (long): First integer number.
        b (long): Second integer number.

    Returns:
        (long, long, long): Three-tuple representing
        (gcd, Bezout's identity coefficient, Bezout's identity coefficient).
    """
def egcd(a: int, b: int) -> tuple[int, int, int] {
    r1 = a;
    r2 = b;
    s1 = 1;
    s2 = 0;
    t1 = 0;
    t2 = 1;
    while r2 > 0 {
        q = r1 // r2;
        r = r1 - q * r2;
        r1 = r2;
        r2 = r;
        s = s1 - q * s2;
        s1 = s2;
        s2 = s;
        t = t1 - q * t2;
        t1 = t2;
        t2 = t;
    }
    return (r1, s1, t1);
}