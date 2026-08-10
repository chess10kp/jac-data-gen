"""
    check if next below cell is empty
    :param i:
    :param j:
    :param field:
    :return: True if next below cell is empty, False otherwise
    """
def is_next_south_cell_empty(i: int, j: int, field: list[list[str]]) -> bool {
    if i == len(field) - 1 {
        return field[0][j] == '.';
    }
    return field[i + 1][j] == '.';
}