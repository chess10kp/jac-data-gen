"""Take a color like #87c95f and produce a lighter or darker variant."""
def color_variant(hex_color: str, brightness_offset: int = 1) -> str {
    if len(hex_color) != 7 {
        raise Exception("Passed %s into color_variant(), needs to be in #87c95f format." % hex_color);
    }
    rgb_hex = [hex_color[x:(x + 2)] for x in [1, 3, 5]];
    new_rgb_int = [(int(hex_value, 16) + brightness_offset) for hex_value in rgb_hex];
    new_rgb_int = [min(255, max(0, i)) for i in new_rgb_int];
    return "#%02x%02x%02x" % (new_rgb_int[0], new_rgb_int[1], new_rgb_int[2]);
}