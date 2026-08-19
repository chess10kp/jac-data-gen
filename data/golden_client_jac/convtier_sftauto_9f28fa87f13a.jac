def sort_array_descending(arr: Any) -> object {
    n = len(arr);
    for i in range((n - 1)) {
        for j in range((i + 1), n) {
            if (arr[i] < arr[j]) {
                (arr[i], arr[j]) = (arr[j], arr[i]);
            }
        }
    }
    return arr;
}



with entry {
    print(sort_array_descending([2, -9]));
    print(sort_array_descending([2]));
    print(sort_array_descending([34]));
}
