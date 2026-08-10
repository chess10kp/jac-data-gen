"""Midpoint circle algorithm — bitmapped circle as runlengths per row."""
def getCircle(x0: int, y0: int, radius: int) -> dict[int, list[int]] {
    points: dict[int, list[int]] = {};
    x = radius;
    y = 0;
    radius_error = 1 - x;
    while x >= y {
        points[y + y0] = [-x + x0, x + x0];
        points[x + y0] = [-y + x0, y + x0];
        points[-y + y0] = [-x + x0, x + x0];
        points[-x + y0] = [-y + x0, y + x0];
        y += 1;
        if radius_error < 0 {
            radius_error += 2 * y + 1;
        } else {
            x -= 1;
            radius_error += 2 * (y - x + 1);
        }
    }
    return points;
}