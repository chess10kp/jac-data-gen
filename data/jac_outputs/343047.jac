"""Take the last element as the pivot,
     and place that element in the correct sorted position by moving all smaller items to the left of the pivot
     and all larger items to the right of the pivot"""
def partition(arr: list[int], low: int, high: int) -> int {
    i = low - 1;
    pivot = arr[high];
    for j in range(low, high) {
        if arr[j] <= pivot {
            i += 1;
            (arr[i], arr[j]) = (arr[j], arr[i]);
        }
    }
    (arr[i + 1], arr[high]) = (arr[high], arr[i + 1]);
    return i + 1;
}