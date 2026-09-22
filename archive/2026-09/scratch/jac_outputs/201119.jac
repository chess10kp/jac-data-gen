"""Return point[x][y] if in the boundary, return None if not."""
def get_point(inputs: list[list[int]], x: int, y: int) -> int | None {
    if x < 0 or y < 0 or x >= len(inputs) or y >= len(inputs[0]) {
        return None;
    }
    return inputs[x][y];
}