def bubble_sort(arr: Any) -> object {
    n = len(arr);
    for i in range(n) {
        for j in range((n - i - 1)) {
            if (arr[j] < arr[(j + 1)]) {
                (arr[j], arr[(j + 1)]) = (arr[(j + 1)], arr[j]);
            }
            if (((arr[j] % 2) != 0) and ((arr[(j + 1)] % 2) == 0)) {
                (arr[j], arr[(j + 1)]) = (arr[(j + 1)], arr[j]);
            }
        }
    }
    return arr;
}



with entry {
    print(bubble_sort([4, 2, 1]));
    print(bubble_sort([2, 1]));
    print(bubble_sort([5, 5]));
}
