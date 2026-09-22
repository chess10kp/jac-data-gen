"""Return True if target is found in indicated portion of a Python list.
       The search only considers the portion from data[low] to data[high] inclusive.
    """
def binary_search(data: list[int], target: int, low: int, high: int) -> bool {
    if low > high {
        return False;
    }
    mid = (low + high) // 2;
    if target == data[mid] {
        return True;
    }
    if target < data[mid] {
        return binary_search(data, target, low, mid - 1);
    }
    return binary_search(data, target, mid + 1, high);
}