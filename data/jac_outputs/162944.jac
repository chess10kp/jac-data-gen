"""Return list of all the slices."""
def _slice_list(`obj: tuple[slice | int, ...] | list[slice | int]) -> list[slice] {
    result = [];
    if not isinstance(`obj, (tuple, list)) {
        return result;
    }
    for o in `obj {
        if isinstance(o, int) {
            result.append(slice(o, o + 1));
        } elif isinstance(o, slice) {
            result.append(o);
        }
    }
    return result;
}