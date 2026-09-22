"""Convert the two pairs of (lower, left), (top, right) in (lat, lon)
    into the four pairs of (lat, lon) of the corners."""
def LLTR2domain(lowerleft: tuple[float, float], topright: tuple[float, float]) -> list[tuple[float, float]] {
    (xa, ya) = lowerleft;
    (xb, yb) = topright;
    return [(xa, ya), (xa, yb), (xb, yb), (xb, ya)];
}