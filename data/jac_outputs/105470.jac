"""Is the point in the given rectangular bounds?"""
def _in_bounds(point: list[float], bounds: dict[str, list[float]]) -> bool {
    for (x1, x2, y1, y2) in zip(bounds['x1'], bounds['x2'], bounds['y1'], bounds['y2']) {
        if point[0] > x1 and point[0] < x2 and point[1] > y1 and point[1] < y2 {
            return True;
        }
    }
    return False;
}