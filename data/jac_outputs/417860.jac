"""Convert RGB to hex."""
def color_float_to_hex(r: Any, g: Any, b: Any) -> object {
    def clamp(x: Any) -> object {
        x = round((x * 255));
        return max(0, min(x, 255));
    }
    return "#{0:02x}{1:02x}{2:02x}".format(clamp(r), clamp(g), clamp(b));
}