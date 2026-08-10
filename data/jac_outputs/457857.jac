"""Returns a copy of the given board_state with the desired move applied."""
def apply_move(
    board_state: tuple[tuple[int, int, int], tuple[int, int, int], tuple[int, int, int]],
    move: tuple[int, int],
    side: int
) -> tuple[tuple[int, int, int], tuple[int, int, int], tuple[int, int, int]] {
    (move_x, move_y) = move;
    rows: list[tuple[int, int, int]] = [];
    for x in range(3) {
        if move_x == x {
            temp = list(board_state[x]);
            temp[move_y] = side;
            rows.append(tuple(temp));
        } else {
            rows.append(board_state[x]);
        }
    }
    return tuple(rows);
}