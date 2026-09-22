"""Recursive quicksort"""
def rquicksort(arr: list[int]) -> list[int] {
    if len(arr) <= 1 {
        return arr;
    }
    return rquicksort([i for i in arr[1:] if i < arr[0]])
        + [arr[0]]
        + rquicksort([i for i in arr[1:] if i > arr[0]]);
}