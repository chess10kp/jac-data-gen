"""Get the value at the x,y coordinates in the matrix."""
def get_value(matrix: list[list], cell: tuple[int, int]) -> str {
    (row, col) = cell;
    return str(matrix[row][col]);
}