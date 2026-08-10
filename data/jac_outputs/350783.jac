"""Radius of kernel for Kamb-style smoothing."""
def _kamb_radius(n: int, sigma: float) -> float {
    a = sigma ** 2 / (float(n) + sigma ** 2);
    return 1 - a;
}