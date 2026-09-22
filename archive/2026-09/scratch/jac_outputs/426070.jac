"""Inverse of a mod m."""
def inverse_mod(a: Any, m: Any) -> object {
    if ((a < 0) or (m <= a)) {
        a = a % m;
    }
    (c, d) = (a, m);
    (uc, vc, ud, vd) = (1, 0, 0, 1);
    while (c != 0) {
        (q, c, d) = divmod(d, c) + (c, );
        (uc, vc, ud, vd) = ((ud - (q * uc)), (vd - (q * vc)), uc, vc);
    }
    assert (d == 1);
    if (ud > 0) {
        return ud;
    } else {
        return (ud + m);
    }
}