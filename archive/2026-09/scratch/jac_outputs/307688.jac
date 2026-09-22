"""Recursively convert list of nested lists/tuples to list of nested lists with elements coerced to integers."""
def nested_list_elements_to_int(mask: list | tuple | int | str) -> list | int {
    if isinstance(mask, (list, tuple)) {
        return list(map(nested_list_elements_to_int, mask));
    } else {
        return int(mask);
    }
}