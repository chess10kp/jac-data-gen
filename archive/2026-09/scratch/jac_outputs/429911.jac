"""Minimum bolt spacing."""
def bolt_min_dist(d_0: float) -> tuple[float, float, float, float, float] {
    e_1 = 1.2 * d_0;
    e_2 = 1.2 * d_0;
    e_3 = 1.5 * d_0;
    p_1 = 2.2 * d_0;
    p_2 = 2.4 * d_0;
    return (e_1, e_2, e_3, p_1, p_2);
}