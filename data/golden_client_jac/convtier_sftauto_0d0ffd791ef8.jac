def custom_sort(arr: Any) -> object {
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
    print(custom_sort([81]));
    print(custom_sort([]));
    print(custom_sort(['a']));
}
