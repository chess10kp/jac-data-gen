"""Returns ith diagonal of matrix, where i is the diag_index."""
def diagonal(mat: list[list[int]], diag_index: int) -> list[int] {
    [
        mat[j % len(mat)][(diag_index + j) % len(mat)] for j in range(len(mat))
    ]
}