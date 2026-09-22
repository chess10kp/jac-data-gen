"""
Computes the time of flight since perigee passage at particular eccentric
anomaly for paraboliparabolic orbit.
"""
def kepler_parabolic(B: float) -> float {
    B + (1 / 3) * B ** 3
}