def reverse_array(arr: Any) -> object {
    if (len(arr) == 0) {
        return [];
    } else {
        return ([arr[-1]] + reverse_array(arr[:-1]));
    }
}



with entry {
    print(reverse_array([]));
}
