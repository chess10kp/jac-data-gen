"""Binary search on a sorted list with optional custom comparator."""
def binary_search(
    items: list[object],
    item: object,
    comparator: Callable[[object, object], int] = lambda (x: object, y: object) -> int {
        0 if x == y else 1 if x > y else -1
    },
    lo: int = 0,
    hi: int | None = None,
    insertion_index: bool = False
) -> int | tuple[int, int] {
    if hi is None {
        hi = len(items);
    }
    while lo < hi {
        mid = (lo + hi) // 2;
        comparison = comparator(item, items[mid]);
        if comparison == 0 {
            return mid if not insertion_index else (mid, mid);
        } elif comparison == 1 {
            lo = mid + 1;
        } else {
            hi = mid;
        }
    }
    return -1 if not insertion_index else (-1, lo);
}