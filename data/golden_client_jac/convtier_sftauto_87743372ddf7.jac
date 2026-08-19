def bubble_sort_descending(arr: Any) -> object {
    n = len(arr);
    for i in range((n - 1)) {
        for j in range((n - i - 1)) {
            if (arr[j] < arr[(j + 1)]) {
                (arr[j], arr[(j + 1)]) = (arr[(j + 1)], arr[j]);
            }
        }
    }
    return arr;
}



with entry {
    print(bubble_sort_descending([4, 3, 2, 1]));
    print(bubble_sort_descending([3, 2, 1]));
    print(bubble_sort_descending([5, 5, 5]));
}
