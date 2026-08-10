"""Return the winner of the line if one exists.

    Otherwise return None.

    A line is a row, a column or a diagonal.
    """
def find_winner_line(line: Any) -> object {
    if (len(line) != 3) {
        raise ValueError('invalid line');
    }
    symbols = `set(line);
    if (len(symbols) == 1) {
        return line[0];
    }
    return None;
}