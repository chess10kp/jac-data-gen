"""
Calculate coo of points in a resized img
in pts pair of coo (x,y)
"""
def resize_pts(
    pts: list[tuple[float, float]],
    ow: float,
    oh: float,
    nw: float,
    nh: float,
    pos_w: float,
    pos_h: float
) -> list[tuple[float, float]] {
    return [
        (p[0] / float(ow) * nw + pos_w, p[1] / float(oh) * nh + pos_h)
        for p in pts
    ];
}