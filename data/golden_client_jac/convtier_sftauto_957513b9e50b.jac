def selection_sort(arr: Any) -> object {
    n = len(arr);
    for i in range(n) {
        max_idx = i;
        for j in range((i + 1), n) {
            if (arr[j] > arr[max_idx]) {
                max_idx = j;
            }
        }
        (arr[i], arr[max_idx]) = (arr[max_idx], arr[i]);
    }
    return arr;
}



with entry {
    print(selection_sort([81]));
    print(selection_sort([]));
    print(selection_sort(['a']));
}
