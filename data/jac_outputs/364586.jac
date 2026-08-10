"""Maintain invariant of arr[low] < key <= arr[high]."""
def binary_search_return_first_invariant(
    arr: list[int], low: int, high: int, key: int
) -> int {
    if arr[low] >= key {
        return low;
    }
    if arr[high] < key {
        return high + 1;
    }
    while low + 1 < high {
        mid = (low + high) // 2;
        if arr[mid] < key {
            low = mid;
        } else {
            high = mid;
        }
    }
    return high;
}