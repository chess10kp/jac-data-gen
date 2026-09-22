"""
    Finds the highest place at the left for a panel with size_x
    :param lines:
    :param size_x:
    :return: line with row, col, len
    """
def find_place(lines: Any, size_x: Any) -> object {
    for line in lines {
        if (line['len'] >= size_x) {
            return line;
        }
    }
}