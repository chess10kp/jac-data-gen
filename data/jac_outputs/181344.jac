"""Scales a cube coord."""
def scale(c: tuple[int, int, int], s: int | float) -> tuple[int | float, int | float, int | float] {
    (cx, cz, cy) = c;
    return (s * cx, s * cz, s * cy);
}