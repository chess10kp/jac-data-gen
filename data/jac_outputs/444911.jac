"""Test each of the nine 3x3 sub-grids (also known as blocks)."""
def test_sub_grids(board: list[list[int]]) -> bool {
    sub_grids = [
        board[0][0:3] + board[1][0:3] + board[2][0:3],
        board[0][3:6] + board[1][3:6] + board[2][3:6],
        board[0][6:] + board[1][6:] + board[2][6:],
        board[3][0:3] + board[4][0:3] + board[5][0:3],
        board[3][3:6] + board[4][3:6] + board[5][3:6],
        board[3][6:] + board[4][6:] + board[5][6:],
        board[6][0:3] + board[7][0:3] + board[8][0:3],
        board[6][3:6] + board[7][3:6] + board[8][3:6],
        board[6][6:] + board[7][6:] + board[8][6:]
    ];
    for row in sub_grids {
        if sorted(row) != [1, 2, 3, 4, 5, 6, 7, 8, 9] {
            return False;
        }
    }
    return True;
}