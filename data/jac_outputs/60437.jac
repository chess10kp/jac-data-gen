"""
    remove list elements according to a list of indices to be removed from that list
    """
def remove_multiple_elements_from_list(a_list: list[int], indices_to_be_removed: list[int]) -> list[int] {
    return [x for (i, x) in enumerate(a_list) if i not in indices_to_be_removed];
}