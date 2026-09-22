"""Check if idx is slice."""
def is_slice(idx: int | str | float | bool | list | tuple | dict | slice | None) -> bool {
    return `type(idx) == slice;
}