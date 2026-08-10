"""
Helper function to return the equation of a line
passing through any two points.

Returns (slope, intercept) or (None, xposition) if the slope is infinite.
"""
def line_from_two_points(x1: float, y1: float, x2: float, y2: float) -> tuple[float, float] | tuple[None, float] {
    xdiff = x2 - x1;
    if abs(xdiff) > 0.0 {
        ydiff = y2 - y1;
        slope = ydiff / xdiff;
        intercept = y1 - slope * x1;
        return (slope, intercept);
    }
    return (None, x1);
}