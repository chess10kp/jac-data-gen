"""Returns whether or not given color is valid in the hexadecimal format."""
def validate_color(color: int | str | float | bool | None) -> bool {
    return isinstance(color, str) and len(color) == 7 and color[0] == "#";
}