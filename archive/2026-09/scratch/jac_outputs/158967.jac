"""create board representation of board string
    returns a list of string representing board characters
    of 'x', 'o' and space ' '.
    An empty space list is added so that board index starts at 1.
    """
def create_board(board_str: str) -> list[str] {
    return [" "] + list(board_str);
}