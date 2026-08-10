"""Calculate the number of elements in nested list."""
def recursive_len(item: list | int | str | float | bool) -> int {
    if `type(item) == list {
        return sum(recursive_len(subitem) for subitem in item);
    }
    return 1;
}