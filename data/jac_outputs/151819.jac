"""
[1/a^2, 0, 1/b^2, 0, 0, -1]
"""
def get_ellipse_equation_coefficient_by_simplest_focus_add(
    x1: int | float, y1: int | float, x2: int | float, y2: int | float, add: int | float
) -> list[float] {
    if y1 == 0 {
        a = add / 2;
        aa = a * a;
        c: float = abs(x1);
        bb = aa - (c ** 2);
        return [1 / aa, 0, 1 / bb, 0, 0, -1];
    }
    b = add / 2;
    bb = b * b;
    c: float = abs(y1);
    aa = bb - (c ** 2);
    return [1 / aa, 0, 1 / bb, 0, 0, -1];
}