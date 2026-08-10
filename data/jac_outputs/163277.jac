"""
    Return True if the coordinates are on the board, otherwise False.
    """
def isValidMove(x: Any, y: Any) -> object {
    return ((x >= 0) and (x <= 59) and (y >= 0) and (y <= 14));
}