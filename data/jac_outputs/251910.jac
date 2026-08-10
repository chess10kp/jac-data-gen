""" Remove idxs from a geometry
    """
def remove(geo: tuple | list, idxs: tuple[int, ...] = ()) -> tuple {
    return tuple(
        row
        for (i, row) in enumerate(geo)
        if i not in idxs
    );
}