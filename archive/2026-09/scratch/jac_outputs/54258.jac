"""Overload of list_pop that executes a Python list append."""
def _py_list_pop(list_: list[int], i: int | None) -> tuple[list[int], int] {
    if i is None {
        x = list_.pop();
    } else {
        x = list_.pop(i);
    }
    return (list_, x);
}