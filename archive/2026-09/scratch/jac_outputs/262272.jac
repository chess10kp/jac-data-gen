"""
Searches for first occurance of the provided target in the given array.
If target found then returns index of it, else None
Time Complexity = O(log n)
Space Complexity = O(1)
"""
def binary_search(arr: list[int], target: int) -> int | None {
    first = 0;
    last = len(arr) - 1;
    while first <= last {
        mid = (last + first) // 2;
        if arr[mid] == target {
            return mid;
        }
        if arr[mid] > target {
            last = mid - 1;
        }
        if arr[mid] < target {
            first = mid + 1;
        }
    }
    return None;
}