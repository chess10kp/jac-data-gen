"""
    Use the Bezout law to calculate the inverse of e to the modulus of phi.
    """
def inverse_a_mod_p(a: int, p: int) -> int {
    (s, t, sn, tn, r) = (1, 0, 0, 1, 1);
    while r != 0 {
        q = p // a;
        r = p - q * a;
        (st, tt) = (sn * -q + s, tn * -q + t);
        (s, t) = (sn, tn);
        (sn, tn) = (st, tt);
        p = a;
        a = r;
    }
    return t;
}