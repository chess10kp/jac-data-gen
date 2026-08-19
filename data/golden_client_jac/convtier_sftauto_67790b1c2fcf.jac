def first_consecutive_index(arr: Any) -> object {
    for i in range((len(arr) - 3)) {
        if (arr[i] == arr[(i + 1)] == arr[(i + 2)] == arr[(i + 3)]) {
            return i;
        }
    }
    return -1;
}



with entry {
    print(first_consecutive_index('hello'));
}
