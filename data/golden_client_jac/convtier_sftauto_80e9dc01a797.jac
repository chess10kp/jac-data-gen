def sort_array_descending(arr: Any) -> object {
    for i in range(len(arr)) {
        for j in range((len(arr) - i - 1)) {
            if (arr[j] < arr[(j + 1)]) {
                (arr[j], arr[(j + 1)]) = (arr[(j + 1)], arr[j]);
            }
        }
    }
    return arr;
}



with entry {
    print(sort_array_descending([81]));
    print(sort_array_descending([]));
    print(sort_array_descending(['a']));
}
