"""Convert CIE1976 u'v' to CIE1931 xy coordinates."""
def uv76_to_xy(u76: float, v76: float) -> tuple[float, float] {
    denominator = (9 * u76) / 2 - 12 * v76 + 9;
    if denominator == 0.0 {
        (x, y) = (0.0, 0.0);
    } else {
        x = (27 * u76) / 4 / denominator;
        y = (3 * v76) / denominator;
    }
    return (x, y);
}