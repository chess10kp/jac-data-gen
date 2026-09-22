"""
Finds the kth largest element in the given array arr of integers.
"""
def find_kth(arr: list[int], k: int | float) -> int {
    if not isinstance(k, (int, float)) or k < 0 {
        raise ValueError("Expected k to be a valid number");
    }
    if k == 1 or k == 0 or k > len(arr) {
        return max(arr);
    }
    kth = int(k);
    current_max = max(arr);
    new_array = [x for x in arr if x != current_max];
    return find_kth(new_array, kth - 1);
}