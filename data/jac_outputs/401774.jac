"""
    Sort the array with the given index and return a list of
    (<element>, <original index>, <new index>) tuples.
    """
def sort_by_index_with_for_loop(index: list[int], array: list[str]) -> list[tuple[str, int, int]] {
    sorted_list = [];
    for i in range(len(array)) {
        sorted_list.append((array[index[i]], index[i], i));
    }
    return sorted_list;
}