""" Normalize a collection of points in
    homogeneous coordinates so that last row = 1. """
def normalizeHomogenious(points: Any) -> object {
    for row in points {
        row /= points[-1];
    }
    return points;
}