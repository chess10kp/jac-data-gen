def bubble_sort_descending(arr: list[int]) -> list[int] {
    n = len(arr);
    for i in range(n - 1) {
        for j in range(n - i - 1) {
            if arr[j] < arr[j + 1] { (arr[j], arr[j + 1]) = (arr[j + 1], arr[j]); }
        }
    }
    return arr;
}

with entry {
    print(bubble_sort_descending([3, 1, 2, 5, 4]));
}
