def sort_array(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    }
    max_value = max(arr);
    max_index = arr.index(max_value);
    (arr[0], arr[max_index]) = (arr[max_index], arr[0]);
    return ([max_value] + sort_array(arr[1:]));
}



with entry {
    print(sort_array([81]));
    print(sort_array([]));
    print(sort_array(['a']));
}
