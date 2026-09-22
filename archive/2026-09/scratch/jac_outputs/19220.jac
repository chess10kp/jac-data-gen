import colorsys;

"""Map each category color a good distance away from each other on the HSV color space."""
def to_color(category: int) -> tuple[float, float, float] {
    v = (category - 1) * (137.5 / 360);
    colorsys.hsv_to_rgb(v, 1, 1)
}