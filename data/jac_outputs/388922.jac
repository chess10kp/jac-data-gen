"""Interpolate between points."""
def interpolate(p1: float, p2: float, d_param: float, dist: float) -> float {
    alpha = min(max(d_param / dist, 0.0), 1.0);
    (1.0 - alpha) * p1 + alpha * p2
}