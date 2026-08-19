def insertion_sort(arr: Any) -> object {
    for i in range(1, len(arr)) {
        key = arr[i];
        j = i - 1;
        while ((j >= 0) and (arr[j] > key)) {
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
