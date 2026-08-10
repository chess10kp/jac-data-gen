"""Check buildings of unique height in each row.

    Return True if buildings in a row have unique length, False otherwise.
    """
def check_uniqueness_in_rows(board: list[str]) -> bool {
    new_lst = [els[1:6] for els in board[1:6]];
    for row in new_lst {
        for i in range(5) {
            if row.count(row[i]) > 1 {
                return False;
            }
        }
    }
    return True;
}