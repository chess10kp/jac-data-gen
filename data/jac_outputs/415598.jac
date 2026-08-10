"""
    Square distance between point and a segment
    """
def getSquareSegmentDistance(
    p: tuple[float, float],
    p1: tuple[float, float],
    p2: tuple[float, float]
) -> float {
    x = p1[0];
    y = p1[1];
    dx = p2[0] - x;
    dy = p2[1] - y;
    if dx != 0 or dy != 0 {
        t = ((p[0] - x) * dx + (p[1] - y) * dy) / (dx * dx + dy * dy);
        if t > 1 {
            x = p2[0];
            y = p2[1];
        } elif t > 0 {
            x += dx * t;
            y += dy * t;
        }
    }
    dx = p[0] - x;
    dy = p[1] - y;
    return dx * dx + dy * dy;
}