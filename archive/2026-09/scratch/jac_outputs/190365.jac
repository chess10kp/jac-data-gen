"""Check buildings of unique height in each row.

    Return True if buildings in a row have unique length, False otherwise.
    """
def check_uniqueness_in_rows(board: list[str]) -> bool {
    for row in board[1:-1] {
        chars = list(row[1:-1]);
        while '*' in chars {
            chars.remove('*');
        }
        if len(set(chars)) != len(chars) {
            return False;
        }
    }
    return True;
}