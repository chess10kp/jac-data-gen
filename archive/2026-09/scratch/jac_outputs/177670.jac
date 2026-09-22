""" Selection Sort
        Complexity: O(n^2)
    """
def selection_sort(arr: list[int]) -> list[int] {
    for i in range(len(arr)) {
        minimum = i;
        for j in range(i + 1, len(arr)) {
            if arr[j] < arr[minimum] {
                minimum = j;
            }
        }
        (arr[minimum], arr[i]) = (arr[i], arr[minimum]);
    }
    return arr;
}