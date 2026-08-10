"""Create dictionary mapping list items to their indices in the list."""
def _list_to_index_dict[T](lst: list[T]) -> dict[T, int] {
    {item: n for (n, item) in enumerate(lst)}
}