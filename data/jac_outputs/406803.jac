"""Return True if all items in lst are equal, False otherwise.
Note that check_equal([1, True]) is True."""
def check_equal(lst: list[int | bool | str | float]) -> bool {
    return not lst or lst.count(lst[0]) == len(lst);
}