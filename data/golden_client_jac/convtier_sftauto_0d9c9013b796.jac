def remove_and_shift(arr: Any) -> object {
    if (len(arr) <= 1) {
        return [];
    }
    for i in range((len(arr) - 1)) {
        arr[i] = arr[(i + 1)];
    }
    arr.pop();
    return arr;
}



with entry {
    print(remove_and_shift([]));
}
