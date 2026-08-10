"""Return a RGB color from a hex color string."""
def color_rgb_to_hex(r: int, g: int, b: int) -> str {
    return "{0:02x}{1:02x}{2:02x}".format(round(r), round(g), round(b));
}