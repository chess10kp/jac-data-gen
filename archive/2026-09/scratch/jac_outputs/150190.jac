"""Gets element from nested lists of arbitrary depth."""
def _get_element(lists: object, indices: list[int]) -> object {
    result = lists;
    for i in indices {
        result = result[i];
    }
    return result;
}