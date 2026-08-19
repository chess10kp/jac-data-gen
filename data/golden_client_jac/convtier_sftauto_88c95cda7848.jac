def bubble_sort(arr: Any) -> object {
    n = len(arr);
    for i in range(n) {
        for j in range((n - 1 - i)) {
            if (arr[j] > arr[(j + 1)]) {
                (arr[j], arr[(j + 1)]) = (arr[(j + 1)], arr[j]);
            }
        }
    }
    return arr;
}



with entry {
    print(bubble_sort([1, 2, 3, 4]));
    print(bubble_sort([1, 2, 3]));
    print(bubble_sort([5, 5, 5]));
}
