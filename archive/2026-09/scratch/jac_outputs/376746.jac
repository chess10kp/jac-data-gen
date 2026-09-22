"""Checks if colors are similar."""
def is_color_similar(color1: tuple[int, int, int], color2: tuple[int, int, int], overlap: float = 0.05) -> bool {
    (r1, g1, b1) = color1;
    (r2, g2, b2) = color2;
    d = ((r1 - r2) ** 2 + (g1 - g2) ** 2 + (b1 - b2) ** 2) ** (1 / 2.0);
    return d / 510 <= overlap;
}