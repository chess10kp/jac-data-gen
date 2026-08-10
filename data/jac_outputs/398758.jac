"""Return the index of the first occurrence of value in lst, else -1."""
def linear_search(lst: list[int], value: int) -> int {
    i = 0;
    lst_length = len(lst);
    while i != lst_length and value != lst[i] {
        i += 1;
    }
    if i == lst_length {
        return -1;
    }
    return i;
}