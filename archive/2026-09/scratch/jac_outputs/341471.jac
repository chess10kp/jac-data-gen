""" (list of list of str, int) -> str

    Return the characters from the column of the board with index column_index
    as a single string.

    >>> make_str_from_column([['A', 'N', 'T', 'T'], ['X', 'S', 'O', 'B']], 1)
    'NS'
    """
def make_str_from_column(board: list[list[str]], column_index: int) -> str {
    return ''.join(row[column_index] for row in board);
}