glob POSSIBLE_WIN = [
    [[0, 0], [1, 1], [2, 2]],
    [[0, 0], [0, 1], [0, 2]],
    [[1, 0], [1, 1], [1, 2]],
    [[2, 0], [2, 1], [2, 2]],
    [[0, 0], [1, 0], [2, 0]],
    [[0, 1], [1, 1], [2, 1]],
    [[0, 2], [1, 2], [2, 2]],
    [[0, 2], [1, 1], [2, 0]]
];

"""Returns the winner of the game, if there is one."""
def winner(board: list[list[str | None]]) -> str | None {
    for line in POSSIBLE_WIN {
        mark = board[line[0][0]][line[0][1]];
        if mark is not None and mark == board[line[1][0]][line[1][1]] and mark == board[line[2][0]][line[2][1]] {
            return mark;
        }
    }
    return None;
}