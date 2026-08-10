"""
    Convert rgb color to cmyk color.
    """
def rgb2cmyk(r: Any, g: Any, b: Any) -> object {
    c = 1 - r;
    m = 1 - g;
    y = 1 - b;
    k = min(c, m, y);
    c = min(1, max(0, (c - k)));
    m = min(1, max(0, (m - k)));
    y = min(1, max(0, (y - k)));
    k = min(1, max(0, k));
    return (c, m, y, k);
}