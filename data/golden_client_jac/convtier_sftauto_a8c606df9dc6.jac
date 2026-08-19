def is_sorted(arr: Any) -> object {
    n = len(arr);
    for i in range(1, n) {
        if (arr[i] < arr[(i - 1)]) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_sorted('hello'));
    print(is_sorted([81]));
}
