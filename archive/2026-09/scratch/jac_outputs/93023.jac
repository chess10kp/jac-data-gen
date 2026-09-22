glob ZERO = 1e-10;

"""Compute lift for a rule a -> b from a contingency table."""
def rule_lift(f11: float, f10: float, f01: float, f00: float) -> float {
    N = f11 + f10 + f01 + f00;
    supp_ab = f11 / N;
    supp_a = f10 / N;
    supp_b = f01 / N;
    return supp_ab / (supp_a * supp_b + ZERO);
}