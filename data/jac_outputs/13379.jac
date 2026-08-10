"""Filter case_ids, excluding any item in to_filter."""
def filter[T](case_ids: list[T], to_filter: list[T]) -> list[T] {
    return [`case for `case in case_ids if `case not in to_filter];
}