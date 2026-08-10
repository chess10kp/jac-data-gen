"""Utility function to create n x m matrix of a given value."""
def _matrix(n: int, m: int, value: object = None) -> list[list[object]] {
    el = value if callable(value) else lambda (i: int, j: int) { value; };
    matrix = [];
    for i in range(n) {
        row = [];
        matrix.append(row);
        for j in range(m) {
            row.append(el(i, j));
        }
    }
    return matrix;
}