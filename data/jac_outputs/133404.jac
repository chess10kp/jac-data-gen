"""Partition array around pivot; return final pivot index."""
def partition(arr: list[int], start: int, end: int) -> int {
    pivot = arr[end];
    small_idx = start - 1;
    for i in range(start, end) {
        if arr[i] <= pivot {
            small_idx = small_idx + 1;
            (arr[small_idx], arr[i]) = (arr[i], arr[small_idx]);
        }
    }
    small_idx = small_idx + 1;
    (arr[small_idx], arr[end]) = (arr[end], arr[small_idx]);
    return small_idx;
}