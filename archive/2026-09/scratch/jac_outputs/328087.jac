"""Index where t should be inserted in sorted arr (left/right of dups)."""
def bsearch_ins_pos(arr: list[int], t: int, left: bool) -> int {
    low = 0;
    high = len(arr);
    while low < high {
        mid = low + (high - low) // 2;
        if arr[mid] < t {
            low = mid + 1;
        } elif arr[mid] > t {
            high = mid;
        } elif left {
            high = mid;
        } else {
            low = mid + 1;
        }
    }
    return low;
}