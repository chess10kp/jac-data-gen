"""Return a flat tuple of integers to represent the indices.

    Slice objects are not hashable, so we convert them.
    """
def _flatten(indices: list[slice | int] | tuple[slice | int, ...]) -> tuple[int | None, ...] {
    result = [];
    for x in indices {
        if isinstance(x, slice) {
            result.extend([x.start, x.stop, x.step]);
        } else {
            result.append(x);
        }
    }
    return tuple(result);
}