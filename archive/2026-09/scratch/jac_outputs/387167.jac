"""Given a list of 2D points (represented as Point objects), uses "sorted"
    with the "key" argument to create and return a list of the SAME (not copied)
    points sorted in decreasing order based on their Y coordinates, without
    modifying the original list."""
def sort_points_by_Y(list_of_points: list[object]) -> list[object] {
    return sorted(list_of_points, key=lambda (pt: object) { getattr(pt, 'getY')(); }, reverse=True);
}