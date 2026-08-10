"""Binary search algorithm that returns the index of the element to look for."""
def binary_search(array: list[int], low: int, high: int, element: int) -> int {
    if high >= low {
        mid = int((high + low) / 2);
        if array[mid] == element {
            return mid;
        } elif array[mid] > element {
            return binary_search(array, mid + 1, high, element);
        } else {
            return binary_search(array, low, mid - 1, element);
        }
    } else {
        return -1;
    }
}