"""
    Searches through the boards and returns the id of the board if anyone has a full row or a full column.
    If no winner were found, it returns -1.
    """
def check_for_winner(board: list[list[bool]]) -> bool {
    for row in board {
        count = 5;
        for n in row {
            if n is True {
                count -= 1;
            }
        }
        if count < 1 {
            return True;
        }
    }
    for j in range(5) {
        count = 5;
        for k in range(5) {
            if board[k][j] is True {
                count -= 1;
            }
        }
        if count < 1 {
            return True;
        }
    }
    return False;
}