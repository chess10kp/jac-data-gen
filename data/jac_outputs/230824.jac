"""
    >>> upper_bound([1, 2, 2, 3, 4], 2)
    3
    >>> upper_bound([1, 2, 2, 3, 4], 5)
    -1
    """
def upper_bound(l: list[int], k: int) -> int {
    if l[-1] <= k {
        return -1;
    }
    i = len(l) // 2;
    (start, end) = (0, len(l) - 1);
    while start < end {
        if l[i] > k {
            end = i;
        } else {
            start = i + 1;
        }
        i = start + (end - start) // 2;
    }
    return i;
}