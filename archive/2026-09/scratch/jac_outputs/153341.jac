"""Get absolute sum of list."""
def get_abs_sum(lst: list[int]) -> int {
    return sum([abs(x) for x in lst]);
}