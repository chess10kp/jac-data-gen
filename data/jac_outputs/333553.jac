"""Scale the rectangle by x, y."""
def scaleRect(rect: tuple[float, float, float, float], x: float, y: float) -> tuple[float, float, float, float] {
    (x_min, y_min, x_max, y_max) = rect;
    return (x_min * x, y_min * y, x_max * x, y_max * y);
}