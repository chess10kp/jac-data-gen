"""
    Returns ``True`` is the edge has one end in each selection.

    Parameters
    ----------
    edge: tuple[int, int]
    selection_a: collections.abc.Container[collections.abc.Hashable]
    selection_b: collections.abc.Container[collections.abc.Hashable]

    Returns
    -------
    bool
    """
def _edge_is_between_selections(
    `edge: Any, selection_a: Any, selection_b: Any
) -> object {
    return (
        ((`edge[0] in selection_a) and (`edge[1] in selection_b))
        or ((`edge[1] in selection_a) and (`edge[0] in selection_b))
    );
}