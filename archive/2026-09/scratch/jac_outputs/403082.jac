"""Partition sequence into matching and non-matching items."""
def partition[T](predicate: Callable[[T], bool], sequence: list[T]) -> tuple[list[T], list[T]] {
    (matched, nomatch) = ([], []);
    for item in sequence {
        if predicate(item) {
            matched.append(item);
        } else {
            nomatch.append(item);
        }
    }
    return (matched, nomatch);
}