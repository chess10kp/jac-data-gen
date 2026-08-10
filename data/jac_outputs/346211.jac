"""Take a nested list of (x, y) dimensions, return an (y, x) list."""
def rotate_list(l: list[list[int | str]]) -> list[list[int | str | None]] {
    r: list[list[int | str | None]] = [[None for x in range(len(l))] for x in range(len(l[0]))];
    for (row_index, row) in enumerate(l) {
        for (column_index, column_value) in enumerate(row) {
            r[column_index][row_index] = column_value;
        }
    }
    return r;
}