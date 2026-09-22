"""
    bounding box for the points pts
    """
def bounding_box2D(pts: list[list[float]]) -> tuple[float, float, float, float] {
    dim = len(pts[0]);
    bb_min = [min([t[i] for t in pts]) for i in range(dim)];
    bb_max = [max([t[i] for t in pts]) for i in range(dim)];
    return (bb_min[0], bb_min[1], bb_max[0] - bb_min[0], bb_max[1] - bb_min[1]);
}