""" Helper function which returns sum of all used keys and items in the
    value lists of a dictionary """
def _size_of_dict(dictionary: dict[str, list]) -> int {
    size = len(dictionary);
    for value in dictionary.values() {
        size += len(value);
    }
    return size;
}