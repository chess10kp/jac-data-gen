"""Returns the euclidean distance between two points with (i, j) coordinates."""
def euclidean_distance(point_a: tuple[int, int], point_b: tuple[int, int]) -> int {
    (point_a[0] - point_b[0]) ** 2 + (point_a[1] - point_b[1]) ** 2
}