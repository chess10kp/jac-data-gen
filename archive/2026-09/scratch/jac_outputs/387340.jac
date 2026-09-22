"""Wrap a single value in a list, or convert the item to a list."""
def tolist(item: object) -> list[object] {
    if isinstance(item, list) {
        return item as list[object];
    }
    return list(item);
}