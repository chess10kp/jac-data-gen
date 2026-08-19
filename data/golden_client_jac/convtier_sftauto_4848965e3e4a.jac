def reverse_array(arr: Any) -> object {
    left = 0;
    right = len(arr) - 1;
    while (left < right) {
        (arr[left], arr[right]) = (arr[right], arr[left]);
        left += 1;
        right -= 1;
    }
    return arr;
}



with entry {
    print(reverse_array([]));
}
