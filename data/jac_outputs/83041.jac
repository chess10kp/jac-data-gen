"""Disutility of labor supply from the elliptical utility function."""
def elliptical_u(b: float, k: float, upsilon: float, l_tilde: float, n: float) -> float {
    return b * ((1 - (n / l_tilde) ** upsilon) ** (1 / upsilon)) + k;
}