"""Converts an RGB 3-tuple to a hexadeximal color string."""
def rgb2hex(rgb: tuple[int, int, int]) -> str {
    return ('#%02x%02x%02x' % tuple(rgb)).upper();
}