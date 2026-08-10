"""Get positions of the seats adjacent to the seat with row and column."""
def get_adjacent_seat_positions(
    row: Any, column: Any, max_row: Any, max_column: Any
) -> object {
    positions = [];
    for cur_row in range((row - 1), (row + 2)) {
        for cur_column in range((column - 1), (column + 2)) {
            if ((cur_row == row) and (cur_column == column)) {
                continue;
            }
            if ((0 <= cur_row <= max_row) and (0 <= cur_column <= max_column)) {
                positions.append((cur_row, cur_column));
            }
        }
    }
    return positions;
}