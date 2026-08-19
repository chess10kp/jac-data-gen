def sort_array_descending(arr: Any) -> object {
    n = len(arr);
    for i in range((n - 1)) {
        current_max = arr[i];
        max_index = i;
        for j in range((i + 1), n) {
            if (arr[j] > current_max) {
                current_max = arr[j];
                max_index = j;
            }
        }
        (arr[i], arr[max_index]) = (arr[max_index], arr[i]);
    }
    return arr;
}



with entry {
    print(sort_array_descending([81]));
    print(sort_array_descending([]));
    print(sort_array_descending(['a']));
}
