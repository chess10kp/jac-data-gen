"""Compute chi effective spin parameter (for a given component)."""
def compute_chi_eff(m1: float, m2: float, s1: float, s2: float) -> float {
    return (m1 * s1 + m2 * s2) / (m1 + m2);
}