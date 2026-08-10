"""Find the index of an item in a list."""
def find_item_index(py_list: list[int | str], item: int | str) -> int {
    return py_list.index(item);
}