""" Filter items in dictionary by value

    >>> iseven = lambda x: x % 2 == 0
    >>> d = {1: 2, 2: 3, 3: 4, 4: 5}
    >>> valfilter(iseven, d)
    {1: 2, 3: 4}

    See Also:
        keyfilter
        itemfilter
        valmap
    """
def valfilter(
    predicate: Callable[[int], bool],
    d: dict[int, int],
    factory: Callable[[], dict[int, int]] = dict
) -> dict[int, int] {
    rv = factory();
    for (k, v) in d.items() {
        if predicate(v) {
            rv[k] = v;
        }
    }
    return rv;
}