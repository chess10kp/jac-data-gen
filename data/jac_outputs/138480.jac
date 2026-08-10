"""Compute the size of a trending spike (normed - constant units)."""
def spike_height(x: float, x_old: float) -> float {
    sign = -1.0 if x < x_old else 1.0;
    mag: float = abs(x ** 0.25 - x_old ** 0.25);
    mag = mag * (1.0 + 20000.0 / (x + 100.0) ** 2);
    return sign * mag;
}