glob RGB_MAX = 255;

"""Convert an rgb value to normalized components."""
def rgb_to_rgba(rgb: list[int | float] | tuple[int | float, int | float, int | float]) -> tuple[float, float, float] {
    r = rgb[0] / RGB_MAX;
    g = rgb[1] / RGB_MAX;
    b = rgb[2] / RGB_MAX;
    return (r, g, b);
}