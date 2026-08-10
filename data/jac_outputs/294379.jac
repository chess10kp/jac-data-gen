"""Compute weight deltas."""
def _gaussian_gradients(x: float, y: float, a: float, sigma: float, mu: float) -> tuple[float, float] {
    sig2 = sigma ** 2;
    delta_b = (mu / sig2) - (y / sig2) * (2 * sig2 + 1 - y ** 2 + mu * y);
    delta_a = (1 / a) + delta_b * x;
    return (delta_a, delta_b);
}