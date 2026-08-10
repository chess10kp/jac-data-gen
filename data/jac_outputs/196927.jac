"""Checks if someone wins."""
def complete_check(input_board: list[list[str]]) -> bool {
    for board_line in input_board {
        if board_line.count("X") == 5 {
            return True;
        }
    }
    for num in range(5) {
        column = [board_line[num] for board_line in input_board];
        if column.count("X") == 5 {
            return True;
        }
    }
    return False;
}