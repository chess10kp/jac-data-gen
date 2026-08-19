def sort_array(arr: Any) -> object {
    for i in range(len(arr)) {
        for j in range((len(arr) - 1 - i)) {
            if (arr[j] < arr[(j + 1)]) {
                (arr[j], arr[(j + 1)]) = (arr[(j + 1)], arr[j]);
            }
        }
    }
    return arr;
}



with entry {
    print(sort_array([4, 2, 1]));
    print(sort_array([2, 1]));
    print(sort_array([5, 5]));
}
