def is_increasing(arr: Any) -> object {
    for i in range((len(arr) - 1)) {
        if (arr[i] >= arr[(i + 1)]) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_increasing('hello'));
    print(is_increasing([]));
}
