"""Transposes a matrix."""
def transpose_matrix(matrix: list[list[int]]) -> list[list[int]] {
    transpose = [[0] * len(matrix) for _ in range(len(matrix[0]))];
    for (i, row) in enumerate(matrix) {
        for j in range(len(row)) {
            transpose[j][i] = matrix[i][j];
        }
    }
    return transpose;
}