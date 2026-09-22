"""
    Returns the number of partitions of n into m or less parts
    """
def count_restricted_partitions(n: int, m: int, l: int) -> int {
    if n == 0 {
        return 1;
    } elif l == 0 {
        return 0;
    } elif m == 0 {
        return 0;
    }
    return sum(
        count_restricted_partitions(n - i, m - 1, i)
        for i in range(1, min(n, l) + 1)
    );
}