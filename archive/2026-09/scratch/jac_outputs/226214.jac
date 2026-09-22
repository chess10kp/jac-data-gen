"""Handle edge cases when box bounds are outside the image range."""
def adjustEdges(height: int, width: int, point: list[int] | tuple[int, int]) -> tuple[int, int] {
    new_point = [point[0], point[1]];
    if point[0] >= height {
        new_point[0] = height - 1;
    }
    if point[1] >= width {
        new_point[1] = width - 1;
    }
    return tuple(new_point);
}