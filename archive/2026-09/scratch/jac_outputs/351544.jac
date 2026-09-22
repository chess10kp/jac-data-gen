"""2nd order explicit scheme for u''=F(u,t)."""
def ODEStep(
    u: float, um: float, t: float, dt: float, F: Callable[[float, float], float]
) -> float {
    (2 * u) - um + dt * dt * F(u, t)
}