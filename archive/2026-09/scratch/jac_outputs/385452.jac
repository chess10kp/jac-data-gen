"""Give a heuristic evaluation in form of a number
    of how good it would be to make "move" to "game_state". The value is
    higher the better the move, regardless of the player to make it.

    This function give higher values to more central columns.
    """
def heuristic_function_1(game_state: Any, move: Any) -> object {
    return -abs((3 - move));
}