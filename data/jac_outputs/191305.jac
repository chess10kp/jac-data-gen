"""Calculates the lande g factor given L, S and J."""
def lande_g(L: float, S: float, J: float) -> float {
    1.0 + (J * (J + 1.0) + S * (S + 1.0) - L * (L + 1.0)) / (2.0 * J * (J + 1.0))
}