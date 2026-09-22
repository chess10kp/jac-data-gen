"""Check if the board is a winner (one row or column is all zeros)."""
def is_winner(board: list[list[int]]) -> bool {
    for row in board {
        result_sum = 0;
        for val in row {
            result_sum += val;
        }
        if result_sum == 0 {
            return True;
        }
    }
    for j in range(len(board[0])) {
        result_sum = 0;
        for i in range(len(board)) {
            result_sum += board[i][j];
        }
        if result_sum == 0 {
            return True;
        }
    }
    return False;
}