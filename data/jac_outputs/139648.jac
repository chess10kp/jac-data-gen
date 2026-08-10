"""Returns True if x is a dask collection."""
def is_dask_collection(x: int | str | float | bool | bytes | list[int] | dict[str, int] | tuple[int, ...]) -> bool {
    try {
        return getattr(x, '__dask_graph__')() is not None;
    } except (AttributeError, TypeError) {
        return False;
    }
}