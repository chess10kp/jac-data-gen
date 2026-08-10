"""Extend nested lists in lists."""
def extend_list_series(nestlist: list[list[int]]) -> list[int] {
    return [item for n in nestlist for item in n];
}