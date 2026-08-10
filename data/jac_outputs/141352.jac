"""Flattens nested list."""
def flatlist[T](nested_list: list[list[T]]) -> list[T] {
    return [item for inner_list in nested_list for item in inner_list];
}