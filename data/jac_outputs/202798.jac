"""Obtaining of the last index from the `dictionary`, functions returns `-1` if the dict` is empty."""
def get_last_index(dictionary: dict[int, object]) -> int {
    indexes = list(dictionary);
    return indexes[-1] if indexes else -1;
}