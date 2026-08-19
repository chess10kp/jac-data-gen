def sort_array(arr: Any) -> object {
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
    print(sort_array([2, -9]));
    print(sort_array([2]));
    print(sort_array([34]));
}
