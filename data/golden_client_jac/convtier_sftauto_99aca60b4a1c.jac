def sort_array(arr: Any) -> object {
    for i in range(len(arr)) {
        for j in range((i + 1), len(arr)) {
            if (arr[i] > arr[j]) {
                (arr[i], arr[j]) = (arr[j], arr[i]);
            }
        }
    }
    return arr;
}



with entry {
    print(sort_array([2, 7]));
    print(sort_array([2]));
    print(sort_array([34]));
}
