"""Handle index.

If the index is negative, convert it. If the index is out of range, raise
an IndexError.
"""
def handle_index(l: list[object], index: int) -> int {
    if index < 0 {
        index = `type(index)(len(l) + index);
    }
    if not 0 <= index < len(l) {
        raise IndexError("list index out of range");
    }
    return index;
}