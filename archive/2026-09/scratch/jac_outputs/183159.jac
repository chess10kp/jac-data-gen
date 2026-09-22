"""Return index of first occurrence of v in sorted L, or -1 if absent."""
def binary_search(L: list[int], v: int) -> int {
    b = 0;
    e = len(L) - 1;
    while b <= e {
        m = (b + e) // 2;
        if L[m] < v {
            b = m + 1;
        } else {
            e = m - 1;
        }
    }
    if b == len(L) or L[b] != v {
        return -1;
    }
    return b;
}