"""Returns the diff of the two lists."""
def compare_lists(list1: list[str], list2: list[str]) -> tuple[list[str], list[str]] {
    removed = [elem for elem in list1 if elem not in list2];
    added = [elem for elem in list2 if elem not in list1];
    return (added, removed);
}