"""Compute Lennard-Jones potential from C6, C12, distance, and lambda."""
def Lennard_Jones_AB(r: float, C6: float, C12: float, lam: float) -> float {
    (C12 / r ** 12 - C6 / r ** 6) * lam
}