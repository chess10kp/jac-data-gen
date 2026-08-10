"""Convert from transformation matrix to PDF shorthand."""
def _shorthand_from_matrix(matrix: list[list[float | int]]) -> tuple[float, float, float, float, float, float] {
    (a, b) = (matrix[0][0], matrix[0][1]);
    (c, d) = (matrix[1][0], matrix[1][1]);
    (e, f) = (matrix[2][0], matrix[2][1]);
    return tuple(map(float, (a, b, c, d, e, f)));
}