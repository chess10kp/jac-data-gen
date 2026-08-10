"""Eq. (8) of Wallman et al. New J. Phys. 2015."""
def unitarity_decay(A: float, B: float, u: float, m: float) -> float {
    return A + B * u ** m;
}