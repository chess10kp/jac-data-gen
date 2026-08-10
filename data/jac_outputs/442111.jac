"""Convert x,y chromaticity coordinates to XYZ tristimulus values."""
def triwhite(x: float, y: float) -> list[float] {
    X = x / y;
    Y = 1.0;
    Z = (1 - x - y) / y;
    return [X, Y, Z];
}