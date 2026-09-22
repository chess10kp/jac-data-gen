"""Returns a list containing the union of 'x' and 'y', preserving order and removing duplicates."""
def unique_ordered_union(x: list, y: list) -> list {
    return list(dict.fromkeys(list(x) + list(y)).keys());
}