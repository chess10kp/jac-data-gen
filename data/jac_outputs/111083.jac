"""Improvement over binary search when the data is uniformly distributed."""
def interpolation_search(to_be_searched: list[int], searching_for: int) -> int {
    if to_be_searched {
        low = 0;
        high = len(to_be_searched) - 1;
        while low <= high
            and searching_for >= to_be_searched[low]
            and searching_for <= to_be_searched[high] {
            pos = low + int(
                (searching_for - to_be_searched[low]) * (high - low)
                / (to_be_searched[high] - to_be_searched[low])
            );
            if searching_for == to_be_searched[pos] {
                return pos;
            }
            if searching_for < to_be_searched[pos] {
                high = pos - 1;
            } else {
                low = pos + 1;
            }
        }
    }
    return -1;
}