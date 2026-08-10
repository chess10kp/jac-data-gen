"""Binary search for item in arr between left and right indices."""
def binary_search(arr: list[int], left: int, right: int, item: int) -> int {
    if right >= left {
        mid = left + (right - left) // 2;
        if arr[mid] == item {
            return mid;
        }
        if arr[mid] > item {
            return binary_search(arr, left, mid - 1, item);
        }
        return binary_search(arr, mid + 1, right, item);
    }
    return -1;
}