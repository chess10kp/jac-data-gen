"""Creates a matrix of the given size initialized with all zeroes."""
def create_empty_gid_matrix(width: Any, height: Any) -> object {
    return [([0] * width) for row_index in range(height)];
}