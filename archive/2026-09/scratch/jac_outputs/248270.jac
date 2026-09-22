"""Gets the dimension of a position based on the 4 corners of a position."""
def get_dimensions(corners: list[tuple[int, int]]) -> tuple[int, int] {
    (x0, y0) = corners[0];
    (x1, y1) = corners[1];
    (x2, y2) = corners[2];
    (x3, y3) = corners[3];
    x = max([abs(x0 - x1), abs(x0 - x2), abs(x0 - x3)]);
    y = max([abs(y0 - y1), abs(y0 - y2), abs(y0 - y3)]);
    return (x, y);
}