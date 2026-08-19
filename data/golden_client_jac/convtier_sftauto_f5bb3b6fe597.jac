def reverse_array(arr: Any) -> object {
    n = len(arr);
    for i in range((n // 2)) {
        (arr[i], arr[(n - i - 1)]) = (arr[(n - i - 1)], arr[i]);
    }
    return arr;
}



with entry {
    print(reverse_array([81]));
    print(reverse_array([]));
    print(reverse_array(['a']));
}
