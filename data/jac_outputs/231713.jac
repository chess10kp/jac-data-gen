"""Get close to <target> by doing a numeric derivative"""
def _numeric_derivative(
    y0: float,
    y1: float,
    err: float,
    target: float,
    x_min: float,
    x_max: float,
    x0: float,
    x1: float
) -> tuple[float, float, float] {
    if abs(y1 - y0) < err {
        return (0.0, x1, x1);
    }
    x = ((target - y0) / (y1 - y0)) * (x1 - x0) + x0;
    x = min(x, x_max);
    x = max(x, x_min);
    dx = abs(x - x1);
    x0 = x1;
    x1 = x;
    return (dx, x0, x1);
}