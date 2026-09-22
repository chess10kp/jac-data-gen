"""
    Remove the elements of given indices from a tuple.

    Parameters
    ----------
    initTuple : tuple of any
        The given tuple from which we will remove elements.
    indexList : list of ints
        The indices of elements that we want to remove.

    Returns
    -------
    tuple of any
        The tuple after removing elements from initTuple
    """
def tupleRemoveByIndex[T](initTuple: tuple[T, ...], indexList: list[int]) -> tuple[T, ...] {
    index_set = set(indexList);
    return tuple(x for (i, x) in enumerate(initTuple) if i not in index_set);
}