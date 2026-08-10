"""
    This method is used to construct the path from start edge to goal edge
    """
def _reconstruct_path(came_from: Any, start: Any, goal: Any) -> object {
    current = goal;
    path = [];
    while (current != start) {
        path.append(current);
        current = came_from.get(current);
    }
    path.append(start);
    path.reverse();
    return path;
}