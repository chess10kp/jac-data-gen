"""Returns element pairs from `l` in all combinations without repeats, irrespective of order."""
def all_list_element_combinations_as_pairs(l: list[int]) -> list[tuple[int, int]] {
    element_pairs = [];
    for i in range(len(l)) {
        element_pairs += [(l[i], l[j]) for j in range(i, len(l))];
    }
    return element_pairs;
}