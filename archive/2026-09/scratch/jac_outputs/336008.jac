"""For a line through (cx, cy) at angle t, return two points on its perpendicular at distance length."""
def get_normal_points(cx: float, cy: float, cos_t: float, sin_t: float, length: float) -> tuple[float, float, float, float] {
    if length == 0.0 {
        return (cx, cy, cx, cy);
    }
    cos_t1 = sin_t;
    sin_t1 = -cos_t;
    cos_t2 = -sin_t;
    sin_t2 = cos_t;
    x1 = length * cos_t1 + cx;
    y1 = length * sin_t1 + cy;
    x2 = length * cos_t2 + cx;
    y2 = length * sin_t2 + cy;
    return (x1, y1, x2, y2);
}