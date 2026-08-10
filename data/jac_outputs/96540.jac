"""Get indices of point's neighbors in square matrix of size `size`."""
def _get_neighbors(size: int, point: tuple[int, int]) -> list[tuple[int, int]] {
    (i, j) = point;
    neighbors = [(i - 1, j), (i + 1, j), (i, j - 1), (i, j + 1)];
    _valid_neighbor = lambda (neighbor: tuple[int, int]) { all(0 <= x < size for x in neighbor); };
    return list(filter(_valid_neighbor, neighbors));
}