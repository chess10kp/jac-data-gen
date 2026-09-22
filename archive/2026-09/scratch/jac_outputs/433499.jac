"""Handle edge cases when box bounds are outside the image range."""
def adjustEdges(height: int, width: int, point: list[int]) -> tuple[int, int] {
    newPoint = [point[0], point[1]];
    if point[0] >= height {
        newPoint[0] = height - 1;
    }
    if point[1] >= width {
        newPoint[1] = width - 1;
    }
    return tuple(newPoint);
}