"""Returns a len(y) + 1 by len(x) + 1 matrix, where the first row and column
    are filled with 0s and the rest is filled with -1s."""
def _get_edit_distance_matrix(x: str, y: str) -> list[list[int]] {
    matrix = [[-1 for _ in range(len(y) + 1)] for _ in range(len(x) + 1)];
    for j in range(len(matrix[0])) {
        matrix[0][j] = j;
    }
    for (i, _) in enumerate(matrix) {
        matrix[i][0] = i;
    }
    return matrix;
}