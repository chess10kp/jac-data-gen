"""Checks if the piece at location equals query. Returns false if location is out of bounds."""
def square_is(location: tuple[int, int], query: str | None, board: list[list[str | None]]) -> bool {
    (x, y) = location;
    if y < 0 or y >= len(board) {
        return False;
    }
    if x < 0 or x >= len(board[y]) {
        return False;
    }
    return board[y][x] is query;
}