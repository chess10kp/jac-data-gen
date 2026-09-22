"""Check buildings of unique height in each row."""
def check_uniqueness_in_rows(board: list[str]) -> bool {
    for row in board[1:-1] {
        set_row = set(row[1:-1]);
        if len(row[1:-1]) != len(set_row) {
            return False;
        }
    }
    return True;
}