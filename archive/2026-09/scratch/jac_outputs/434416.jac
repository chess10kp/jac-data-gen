"""Returns the intersection between two lists."""
def intersection(lst1: list | None, lst2: list | None) -> list {
    if lst1 is None or lst2 is None {
        return [];
    }
    return [value for value in lst1 if value in lst2];
}