"""Return a list that contains of all the elements of lists without
duplicates and maintaining the order.
"""
def _union_lists(lists: list[list[int]]) -> list[int] {
    seen: dict[int, int] = {};
    return [
        seen.setdefault(x, x) for l in lists
        for x in l
        if x not in seen
    ];
}