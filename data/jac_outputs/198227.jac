"""Manhattan distance."""
def manhattan_distance(x: int, y: int) -> int {
    return (x if x >= 0 else -x) + (y if y >= 0 else -y);
}