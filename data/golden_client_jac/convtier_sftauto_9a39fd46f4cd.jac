def reverse_array(arr: Any) -> object {
    if isinstance(arr, `list) {
        arr.reverse();
        for i in range(len(arr)) {
            arr[i] = reverse_array(arr[i]);
        }
    }
    return arr;
}



with entry {
    print(reverse_array('hello'));
    print(reverse_array('Racecar'));
    print(reverse_array('abcabc'));
}
