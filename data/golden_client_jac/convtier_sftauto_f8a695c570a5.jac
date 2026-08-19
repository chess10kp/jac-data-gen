def insertion_sort(arr: Any) -> object {
    n = len(arr);
    for i in range(1, n) {
        key = arr[i];
        j = i - 1;
        while ((j >= 0) and (key < arr[j])) {
            arr[(j + 1)] = arr[j];
            j -= 1;
        }
        arr[(j + 1)] = key;
    }
    return arr;
}



with entry {
    print(insertion_sort([]));
    print(insertion_sort([-12, 6]));
    print(insertion_sort([-12, -6, -3, 21]));
}
