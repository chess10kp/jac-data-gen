"""copies the given sequence into a new tuple in sorted order"""
def _sort_tuple[T](t: Sequence[T]) -> tuple[T, ...] {
    return tuple(sorted(t));
}