"""Function that converts a board (in FEN notation) in a list of lists of lines of the chess board"""
def boardToArray(board: str) -> list[list[str]] {
    board = board.replace("1", "-").replace("2", "--").replace("3", "---").replace("4", "----").replace("5", "-----").replace("6", "------").replace("7", "-------").replace("8", "--------");
    current_line = [];
    list_board = [];
    for (i, char) in enumerate(board) {
        if char == ' ' {
            list_board.append(current_line);
            break;
        }
        if (i + 1) % 9 == 0 {
            list_board.append(current_line);
            current_line = [];
        } else {
            current_line.append(char);
        }
    }
    return list_board;
}