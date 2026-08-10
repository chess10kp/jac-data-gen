"""
    Tries to convert "a" to an index, returns None on failure.

    The result of a2idx() (if not None) can be safely used as an index to
    arrays/matrices.
    """
def a2idx(a: int | float | bool | str) -> int | None {
    if hasattr(a, "__int__") {
        return int(a);
    }
    if hasattr(a, "__index__") {
        return getattr(a, "__index__")();
    }
}