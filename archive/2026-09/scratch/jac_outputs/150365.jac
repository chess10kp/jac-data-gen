"""Checks that matrix is actually triangular and well-encoded."""
def is_triangular_matrix(matrix: object, expected_dim: int) -> bool {
    if `type(matrix) is not list {
        return False;
    }
    current_dim = expected_dim;
    for row in matrix as list[object] {
        if `type(row) is not list or len(row as list[object]) != current_dim {
            return False;
        }
        current_dim = current_dim - 1;
    }
    return current_dim == 0;
}