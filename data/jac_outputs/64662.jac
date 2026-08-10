"""Return the median value of `sorted_seq`.

    >>> median ([1, 2, 2, 3, 14])
    2

    >>> median ([1, 2, 2, 3, 3, 14])
    2.5

    """
def median_s(sorted_seq: list[int | float]) -> int | float {
    length = len(sorted_seq);
    if length % 2 {
        return sorted_seq[length // 2];
    }
    mid = (length // 2) - 1;
    return (sorted_seq[mid] + sorted_seq[mid + 1]) / 2.0;
}