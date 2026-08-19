def bubble_sort(arr: Any) -> object {
    n = len(arr);
    for i in range(n) {
        for j in range((n - i - 1)) {
            if (arr[j] > arr[(j + 1)]) {
                (arr[j], arr[(j + 1)]) = (arr[(j + 1)], arr[j]);
            }
        }
    }
    return arr;
}



with entry {
    print(bubble_sort([81]));
    print(bubble_sort([]));
    print(bubble_sort(['a']));
}
