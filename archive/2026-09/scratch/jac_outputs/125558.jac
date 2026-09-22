"""Checks if the marker is in the list of points."""
def marker_in_points(points: list[dict[str, int | float]], marker: dict[str, int | float]) -> int | None {
    for (index, point) in enumerate(points) {
        if point["x"] == marker["x"] and point["y"] == marker["y"] and point["z"] == marker["z"] {
            return index;
        }
    }
    return None;
}