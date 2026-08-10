"""Split the line between pt1 and pt2 at position where.

where is an x coordinate when isHorizontal is False, a y coordinate when True.
Return two line segments if split succeeds, otherwise the original line.
"""
def splitLine(pt1: tuple[int, int], pt2: tuple[int, int], where: int, isHorizontal: bool) -> list[tuple[tuple[int, int], tuple[int | float, int | float]]] {
    (pt1x, pt1y) = pt1;
    (pt2x, pt2y) = pt2;
    ax = pt2x - pt1x;
    ay = pt2y - pt1y;
    bx = pt1x;
    `by = pt1y;
    a = (ax, ay)[isHorizontal];
    if a == 0 {
        return [(pt1, pt2)];
    }
    t = (where - (bx, `by)[isHorizontal]) / a;
    if 0 <= t < 1 {
        midPt = (ax * t + bx, ay * t + `by);
        return [(pt1, midPt), (midPt, pt2)];
    }
    return [(pt1, pt2)];
}