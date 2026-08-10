"""Converts RGB components into a packed 24-bit integer."""
def rgb2int(r: int | float, g: int | float, b: int | float) -> int {
    (r, g, b) = (int(abs(r)), int(abs(g)), int(abs(b)));
    return (r << 16) + (g << 8) + b;
}