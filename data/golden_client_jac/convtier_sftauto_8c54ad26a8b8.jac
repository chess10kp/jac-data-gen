def reverse_list(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    } else {
        return (reverse_list(arr[1:]) + [arr[0]]);
    }
}



with entry {
    print(reverse_list([]));
}
