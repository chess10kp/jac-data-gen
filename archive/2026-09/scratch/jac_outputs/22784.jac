"""
Takes a RGB color and returns its grayscale value. See
http://www.johndcook.com/blog/2009/08/24/algorithms-convert-color-grayscale/
for more information.
"""
def cmyk_to_luminance(r: int, g: int, b: int, a: int) -> int | float {
    if (r, g, b) == (0, 0, 0) {
        return a;
    }
    return ((0.299 * r) + (0.587 * g) + (0.114 * b)) * a / 255;
}