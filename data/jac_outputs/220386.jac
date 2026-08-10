"""p = (alpha, u_ref)"""
def powerlaw_u_alpha(x: float, p: tuple[float, float], z_ref: float = 100) -> float {
    p[1] * (x / z_ref) ** p[0]
}