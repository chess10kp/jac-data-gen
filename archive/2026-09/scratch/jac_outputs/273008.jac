"""
    line y = ax + b. returns a,b

    """
def get_line_cf(x0: float, y0: float, x1: float, y1: float) -> tuple[float | None, float | None] {
    same_x = abs(x1 - x0) < 1e-06;
    same_y = abs(y1 - y0) < 1e-06;
    if same_x and same_y {
        return (None, None);
    }
    if same_x {
        a = None;
        b = x0;
    } elif same_y {
        a = 0;
        b = y0;
    } else {
        a = (y1 - y0) / (x1 - x0);
        b = (y0 * x1 - x0 * y1) / (x1 - x0);
    }
    return (a, b);
}