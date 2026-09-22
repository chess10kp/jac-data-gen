"""Define non-linear limb darkening model with four params."""
def nonlinear_limb_darkening(
    mu: float, c0: float = 0.0, c1: float = 0.0, c2: float = 0.0, c3: float = 0.0
) -> float {
    1.0 - (
        c0 * (1.0 - mu ** 0.5)
        + c1 * (1.0 - mu)
        + c2 * (1.0 - mu ** 1.5)
        + c3 * (1.0 - mu ** 2)
    )
}