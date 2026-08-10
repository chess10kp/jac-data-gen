"""Compute Bezout's coefficients."""
def bezout(a: int, b: int) -> tuple[int, int] {
    (r2, r1) = (a, b);
    (s2, s1) = (1, 0);
    (t2, t1) = (0, 1);
    while r1 != 0 {
        q = r2 // r1;
        (r2, r1) = (r1, r2 - q * r1);
        (s2, s1) = (s1, s2 - q * s1);
        (t2, t1) = (t1, t2 - q * t1);
    }
    return (s2, t2);
}