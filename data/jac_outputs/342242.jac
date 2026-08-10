""" (int, int, int) -> int

    Precondition: 0 < row_index <= board_size and
                  0 < col_index <= board_size and
                  1 <= board_size <= 9

    Return the str_index of the cell in the string representation
    of the game board corresponding to the given row and column indices.

    >>> get_position(2, 1, 4)
    4
    >>> get_position(3 ,1, 3)
    6
    """
def get_position(row_index: int, col_index: int, board_size: int) -> int {
    return (row_index - 1) * board_size + col_index - 1;
}