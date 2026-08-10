"""Return game status by current board state."""
def check_game_status(board: list[int]) -> int {
    for t in (1, 2) {
        for j in range(0, 9, 3) {
            if [t, t, t] == board[j:j + 3] {
                return t;
            }
        }
        for j in range(3) {
            if board[j] == t and board[j + 3] == t and board[j + 6] == t {
                return t;
            }
        }
        if board[0] == t and board[4] == t and board[8] == t {
            return t;
        }
        if board[2] == t and board[4] == t and board[6] == t {
            return t;
        }
    }
    if any(cell == 0 for cell in board) {
        return -1;
    }
    return 0;
}