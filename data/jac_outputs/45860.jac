"""Return the coordinates for the box that contains all POINTS."""
def bounding_box(points: list[tuple[int, int]]) -> list[tuple[int, int]] {
    min_x = min(point[0] for point in points);
    min_y = min(point[1] for point in points);
    max_x = max(point[0] for point in points);
    max_y = max(point[1] for point in points);
    return [(min_x, min_y), (max_x, max_y)];
}