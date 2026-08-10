"""
    Returns set of all possible actions (i, j) available on the board.
    """
def actions(board: list[list[int | None]]) -> set[tuple[int, int]] {
    possible_set = set();
    for i in range(len(board)) {
        for j in range(len(board[i])) {
            if board[i][j] is None {
                possible_set.add((i, j));
            }
        }
    }
    return possible_set;
}