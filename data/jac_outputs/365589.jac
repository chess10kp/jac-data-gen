"""dz constrant for edge gap sc touching 2 corner gap sc"""
def _cons8_99(
    m8: float, L88: float, L89: float, d_gap: float, k: float, Cp: float, h_gap: float
) -> float {
    term1 = 2 * h_gap * L88 / m8 / Cp;
    term2 = 2 * k * d_gap / m8 / Cp / L89;
    return 1 / (term1 + term2);
}