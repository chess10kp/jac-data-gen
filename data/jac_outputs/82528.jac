"""
Compute a beta model profile from radius, normalization, core radius, and slope.
"""
def beta_model(r3d_kpc: float, n0: float, r_c: float, beta: float) -> float {
    return n0 * (1 + (r3d_kpc / r_c) ** 2) ** ((-3.0 * beta) / 2.0);
}