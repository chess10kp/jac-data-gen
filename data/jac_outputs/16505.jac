"""Given two polyline vertex lists, append them if needed.

    Polylines to be appended will have the last coordinate of
    the first vertex list be the same as the first coordinate of the
    second vertex list. When appending, we need to eliminate
    one of these coordinates.

    Args:
        currentVL (list): First of two lists of vertexes to check.
        nextVL (list): Second of two lists of vertexes to check.

    Returns:
        tuple: Tuple:

        1. ``True`` if the vertexes were appended, otherwise ``False``.
        2. New vertex list if appended (otherwise ignored).
    """
def polylineAppendCheck(currentVL: list[list[float]], nextVL: list[list[float]]) -> tuple[bool, list[list[float]]] {
    was_appended = False;
    appended_list: list[list[float]] = [];
    last = currentVL[-1];
    first = nextVL[0];
    if last[0] == first[0] and last[1] == first[1] and last[2] == first[2] {
        was_appended = True;
        appended_list = currentVL[:-1] + nextVL;
    }
    return (was_appended, appended_list);
}