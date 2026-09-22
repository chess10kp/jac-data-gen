"""
Return the column-stacked-matrix-basis labels based on a matrix dimension.
"""
def col_labels(matrix_dim: int) -> list[str] {
    if matrix_dim == 0 {
        return [];
    }
    if matrix_dim == 1 {
        return [''];
    }
    return [("(%d,%d)" % (j, i)) for i in range(matrix_dim) for j in range(matrix_dim)];
}