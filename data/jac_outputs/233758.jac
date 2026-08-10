"""Computes the multiplicative inverse of a modulo n using the extended Euclidean algorithm."""
def mod_inv(a: int, n: int) -> int {
    (t, r) = (0, n);
    (new_t, new_r) = (1, a);
    while new_r != 0 {
        quotient = r // new_r;
        (t, new_t) = (new_t, t - quotient * new_t);
        (r, new_r) = (new_r, r - quotient * new_r);
    }
    if r > 1 { raise Exception("a is not invertible"); }
    if t < 0 { t = t + n; }
    return t;
}