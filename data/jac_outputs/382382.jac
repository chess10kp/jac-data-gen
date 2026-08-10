"""Insertion Sort. Complexity: O(n^2)."""
def insertion_sort(arr: list[int], simulation: bool = False) -> list[int] {
    for i in range(len(arr)) {
        cursor = arr[i];
        pos = i;
        while pos > 0 and arr[pos - 1] > cursor {
            arr[pos] = arr[pos - 1];
            pos = pos - 1;
        }
        arr[pos] = cursor;
    }
    return arr;
}