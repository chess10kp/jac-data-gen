"""Converts RGB to GrayScale using luminosity method."""
def rgbToGray(r: float, g: float, b: float) -> float {
    g = 0.21 * r + 0.72 * g + 0.07 * b;
    return g;
}