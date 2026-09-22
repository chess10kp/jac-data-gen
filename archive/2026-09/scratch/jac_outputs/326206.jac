"""Returns a string representation of the board."""
def _board_to_string(board: list[list[str]]) -> str {
    "\n".join("".join(row) for row in board)
}