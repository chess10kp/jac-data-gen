"""Return all coordinates in the column of (col, row) as a list.

    Args:
        row (int): The row of the field.
        col (int): The column of the field.
        width (int): The width of the sudoku.
        height (int): The height of the sudoku.
        include (bool): Whether or not to include (row, col).

    Returns:
        list of (int, int): list of pairs (row, column) of all fields in
                            the same column.
    """
def column_of(
    row: int, col: int, width: int = 3, height: int = 3, `include: bool = True
) -> list[tuple[int, int]] {
    return [
        (i, col)
        for i in range(width * height)
        if `include or i != row
    ];
}