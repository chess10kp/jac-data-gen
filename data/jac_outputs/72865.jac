"""Returns first item in the list or None if empty."""
def first_item[T](l: list[T]) -> T | None {
    l[0] if len(l) > 0 else None
}