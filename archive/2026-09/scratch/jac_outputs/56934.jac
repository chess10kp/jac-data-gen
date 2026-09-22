"""Move the given row to one position right"""
def move_right(board: list[list[int]], row: int) -> list[list[int]] {
    board[row] = board[row][-1:] + board[row][:-1];
    return board;
}