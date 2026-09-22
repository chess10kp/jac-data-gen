"""Creates an ordered list from strings, tuples or other hashable items."""
def ordered_set(iterable: list[str] | list[int] | list[tuple[int, int]]) -> list[str] | list[int] | list[tuple[int, int]] {
    mmap = {};
    ord_set = [];
    for item in iterable {
        if item not in mmap {
            mmap[item] = 1;
            ord_set.append(item);
        }
    }
    return ord_set;
}