"""Calculates the area and centroid of sections defined by
    closed 2D polylines (a list of 2D tuples -
    e.g. [(x1, y1), (x2, y2), ...]). It will also accept
    3D coordinates [(x1, y1, z1), (x2, y2, z2), ...] but ignores
    the z-coordinate in calculating the area (and centroid)

    Example:
    >>> area, _ = perim_area_centroid([(-1, -2, 0), (2, -1, 0), (3, 2, 0)])
    >>> area
    4.0
    """
def perim_area_centroid(perim: list[tuple[float, float] | tuple[float, float, float]]) -> tuple[float, tuple[float, float]] {
    res = [0.0, 0.0, 0.0];
    (x1, y1, *_) = perim[0];
    if perim[0] != perim[-1] {
        perim.append(perim[0]);
    }
    for p2 in perim[1:] {
        (x2, y2, *_) = p2;
        area = (x1 * y2 - x2 * y1) / 2.0;
        res[0] += area;
        res[1] += (x1 + x2) * area / 3.0;
        res[2] += (y1 + y2) * area / 3.0;
        (x1, y1) = (x2, y2);
    }
    return (0.0, (0.0, 0.0)) if res[0] == 0.0 else (res[0], (res[1] / res[0], res[2] / res[0]));
}