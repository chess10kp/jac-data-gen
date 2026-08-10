"""The union of all sets in the iterable collection."""
def BigUnion(iter: Iterable[set[int]]) -> set[int] {
    union = set();
    for s in iter {
        union.update(s);
    }
    return union;
}