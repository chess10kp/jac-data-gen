"""
    Returns a list of the contents of seq with sublists and tuples "exploded".
    The resulting list does not contain any sequences, and all inner sequences
    are exploded.  For example:

    >>> flatten([7,(6,[5,4],3),2,1])
    [7, 6, 5, 4, 3, 2, 1]
    """
def flatten(seq: list | tuple) -> list {
    lst = [];
    for el in seq {
        if isinstance(el, (list, tuple)) {
            lst.extend(flatten(el));
        } else {
            lst.append(el);
        }
    }
    return lst;
}