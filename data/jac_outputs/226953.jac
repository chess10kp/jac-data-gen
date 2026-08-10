"""Remove all `DotDict` instances from `data`.

This function will recursively replace all `DotDict` instances with their
plain Python equivalent.
"""
def undo(data: list | tuple | dict | int | str | float | bool | bytes) -> list | dict | int | str | float | bool | bytes {
    if not isinstance(data, (list, tuple, dict)) {
        return data;
    }
    if isinstance(data, (list, tuple)) {
        return [undo(item) for item in data];
    }
    return {k: undo(v) for (k, v) in data.items()};
}