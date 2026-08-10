"""Convert RGB components to a hex color string."""
def rgb2hex(r: int, g: int, b: int) -> str {
    return '#%02x%02x%02x' % (r, g, b);
}