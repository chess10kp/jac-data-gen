"""
Normalize an HSV or HSL tuple.
Args:
    h: int` in {0, ..., 360} corresponding to hue.
    s: int` in {0, ..., 100} corresponding to saturation.
    x: int` in {0, ..., 100} corresponding to light or value.
Returns:
    The corresponding normalized tuple.
"""
def normalize_color_tuple(h: int, s: int, x: int) -> tuple[float, float, float] {
    return (h / 360, s / 100, x / 100);
}