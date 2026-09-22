"""Find the indices of the first range of consecutive items which satisfy the given predicate.
    Returns (-1, -1) if it there is no such ranges.

    find_range([0, 0, 1, 1, 0], lambda e: e > 0) => (2, 4)
    """
def find_range(iterable: Any, predicate: Any) -> object {
    iterator = enumerate(iterable);
    start_index = next(
        (
            i
            for (i, value) in iterator
            if predicate(value)
        ),
        -1
    );
    if (start_index == -1) {
        return (-1, -1);
    }
    j = start_index;
    for (j, value) in iterator {
        if not predicate(value) {
            end_index = j;
            break;
        }
    } else {
        end_index = j + 1;
    }
    return (start_index, end_index);
}