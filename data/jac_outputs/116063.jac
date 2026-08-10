"""returns a + (a + delta) * z + (a + 2 * delta) * z ** 2 + ..."""
def linear_series(z: float, a: float, delta: float) -> float {
    z1 = 1 - z;
    return (a - (a + delta) * z) / (z1 * z1);
}