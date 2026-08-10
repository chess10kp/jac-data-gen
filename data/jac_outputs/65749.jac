"""Return y3 such that (y2 - y1)/(x2 - x1) = (y3 - y2)/(x3 - x2)."""
def linear_extrap(x1: float, x2: float, x3: float, y1: float, y2: float) -> float {
    (x3 - x2) * (y2 - y1) / (x2 - x1) + y2
}