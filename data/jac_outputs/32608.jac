"""Convert an rgb color to hex."""
def rgb_to_hex(color: tuple[int, int, int, int]) -> str {
    return "#%02x%02x%02x%02x" % (*color,);
}