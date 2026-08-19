def reverse_array(arr: Any) -> object {
    start = 0;
    end = len(arr) - 1;
    while (start < end) {
        (arr[start], arr[end]) = (arr[end], arr[start]);
        start += 1;
        end -= 1;
    }
    return arr;
}



with entry {
    print(reverse_array([81]));
    print(reverse_array([]));
    print(reverse_array(['a']));
}
