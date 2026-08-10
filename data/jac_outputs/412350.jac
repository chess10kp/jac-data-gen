"""Group horizontal or vertical intersections by the given key."""
def groupIntersections(intersections: list[tuple[int, int]], key: int) -> dict[int, list[tuple[int, int]]] {
    grouped_intersections = {};
    for intersection in intersections {
        key_value = intersection[key];
        if key_value not in grouped_intersections.keys() {
            grouped_intersections[key_value] = [];
        }
        group = grouped_intersections[key_value];
        group.append(intersection);
    }
    return grouped_intersections;
}