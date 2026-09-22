"""utility function to return cells in the format the frontend expects"""
def indexer(cell: tuple[int, int]) -> list[int] {
    (col, row) = cell;
    return [row, col];
}