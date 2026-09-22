"""Same as dz_anyND but assume entries are flat arrays of same shape."""
def dz_any1D(hbot: float, zeta: float, hc: float, dCs: float, N: float) -> float {
    return (zeta + hbot) * ((hc / N) + (dCs * hbot)) / (hc + hbot);
}