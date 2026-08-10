"""
    >>> _changes([2, 3, 0, 5])
    [2, 1, -3, 5]
    >>> _changes([2])
    [2]
    """
def _changes(path: list[int]) -> list[int] {
    res = [path[0]];
    res += [p - p_prev for (p, p_prev) in zip(path[1:], path)];
    return res;
}