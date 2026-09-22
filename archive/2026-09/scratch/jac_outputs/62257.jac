"""Clamps an integral type to some interval."""
def clamp(low: float, high: float, val: float) -> float {
    return low if val < low else high if val > high else val;
}