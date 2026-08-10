"""Sort list_to_sort by the order given in sorted_indices."""
def sort_lists[T](sorted_indices: list[int], list_to_sort: list[T]) -> list[T] {
    return [list_to_sort[i] for i in sorted_indices];
}