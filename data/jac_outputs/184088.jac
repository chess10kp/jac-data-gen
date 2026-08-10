"""Return indices of board positions that are None."""
def get_available_moves(board_state: tuple[int | None, ...]) -> list[int] {
    return [i for (i, board_position) in enumerate(board_state) if board_position is None];
}