"""Determines if an item is in my_list, even if nested in a lower-level list."""
def in_nested_list(my_list: list[int | str | list], item: int | str) -> bool {
    if item in my_list {
        return True;
    }
    return any(
        in_nested_list(sublist, item)
        for sublist in my_list
        if isinstance(sublist, list)
    );
}