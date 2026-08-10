"""Computes micro-average over @elems."""
def micro(S: dict[str, float], C: dict[str, float], T: dict[str, float]) -> tuple[float, float, float] {
    s_total = sum(S.values());
    c_total = sum(C.values());
    t_total = sum(T.values());
    P = c_total / s_total if s_total > 0.0 else 0.0;
    R = c_total / t_total if t_total > 0.0 else 0.0;
    F1 = 2 * P * R / (P + R) if c_total > 0.0 else 0.0;
    return (P, R, F1);
}