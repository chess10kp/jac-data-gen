"""Get sliced tuple from start and end."""
def _tuple_slice(tup: tuple[object, ...], start: int, end: int) -> tuple[object, ...] {
    return tup[start:end];
}