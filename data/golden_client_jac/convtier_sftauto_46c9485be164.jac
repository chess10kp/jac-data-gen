def selection_sort(arr: Any) -> object {
    n = len(arr);
    for i in range(n) {
        min_index = i;
        for j in range((i + 1), n) {
            if (arr[j] < arr[min_index]) {
                min_index = j;
            }
        }
        (arr[i], arr[min_index]) = (arr[min_index], arr[i]);
    }
    return arr;
}



with entry {
    print(selection_sort([-9]));
    print(selection_sort([]));
    print(selection_sort(['a']));
}
