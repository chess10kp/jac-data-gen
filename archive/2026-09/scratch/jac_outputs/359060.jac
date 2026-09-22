"""Convert XYZ to CIE1976 u'v' coordinates."""
def XYZ_to_uv76(X: float, Y: float, Z: float) -> tuple[float, float] {
    denominator = X + (15 * Y) + (3 * Z);
    if denominator == 0.0 {
        return (0.0, 0.0);
    }
    return ((4 * X) / denominator, (9 * Y) / denominator);
}