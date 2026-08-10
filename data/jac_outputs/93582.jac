"""
    Translates a move on a bord into a pair of indices. For example:  {'Row':A,'Column':1} ==> (0,0)
    :param move: a dict of the move.
    :return: the pair of indices.
    """
def translate_move_to_coord(move: dict[str, int | str]) -> tuple[int, int] {
    return (ord(move['Row'] as str) - 65, (move['Column'] as int) - 1);
}