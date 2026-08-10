"""Multiply two matrices."""
def multiply(m1: list[list[int]], m2: list[list[int]]) -> tuple[tuple[int, ...], ...] {
    m1_rows = len(m1);
    m1_cols = len(m1[0]);
    m2_cols = len(m2[0]);
    assert m1_cols == len(m2), "Matrix multiplication not defined. Invalid dimensions.";
    new_rows = [];
    for i in range(m1_rows) {
        new_row = [];
        for k in range(m2_cols) {
            val = 0;
            for j in range(m1_cols) {
                val = val + m1[i][j] * m2[j][k];
            }
            new_row.append(val);
        }
        new_rows.append(tuple(new_row));
    }
    return tuple(new_rows);
}