"""Converts a coordinate made by a letter/number couple in the index usable with the array that represents the board."""
def row_column_translation(row: int | str, col: str) -> tuple[int, int] {
    row = int(row) - 1;
    if row % 2 != 0 {
        cols = range(ord("a"), ord("a") + 7, 2);
    } else {
        cols = range(ord("b"), ord("b") + 7, 2);
    }
    if ord(col) not in cols {
        return (-1, -1);
    }
    return (row, cols.index(ord(col)));
}