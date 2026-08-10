"""Check if skyscraper board is not finished, i.e., '?' present on the game board.

Return True if finished, False otherwise."""
def check_not_finished_board(board: list[str]) -> bool {
    all_signs = ''.join(board);
    if '?' in all_signs {
        return False;
    }
    return True;
}