"""Return game status by current board status.

Args:
    board (list): Current board state

Returns:
    int:
        -1: game in progress
        0: draw game,
        1 or 2 for finished game(winner mark code).
"""
def check_game_status(board: list[int]) -> int {
    for t in (1, 2) {
        for j in range(0, 9, 3) {
            if [t] * 3 == [board[i] for i in range(j, j + 3)] {
                return t;
            }
        }
        for j in range(0, 3) {
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
    for i in range(9) {
        if board[i] == 0 {
            return -1;
        }
    }
    return 0;
}