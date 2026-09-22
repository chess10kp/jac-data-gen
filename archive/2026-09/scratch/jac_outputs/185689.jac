"""Returns the reverse of the given list."""
def reverse_iter(lst: list[int]) -> list[int] {
    rev_list = [];
    for num in lst {
        rev_list = [num] + rev_list;
    }
    return rev_list;
}