"""Replace a submatrix region in base with data starting at (x, y)."""
def replace_matrix(base: list[list[int]], x: int, y: int, data: list[list[int]]) -> list[list[int]] {
    data_height = len(data);
    data_width = len(data[0]);
    for _row in range(data_height) {
        for _col in range(data_width) {
            base[y + _row][x + _col] = data[_row][_col];
        }
    }
    return base;
}