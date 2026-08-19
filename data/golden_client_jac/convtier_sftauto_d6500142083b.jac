def insertion_sort_desc(arr: Any) -> object {
    for i in range(1, len(arr)) {
        key = arr[i];
        j = i - 1;
        while ((j >= 0) and (arr[j] < key)) {
            arr[(j + 1)] = arr[j];
            j -= 1;
        }
        arr[(j + 1)] = key;
    }
    return arr;
}



with entry {
    print(insertion_sort_desc([]));
    print(insertion_sort_desc([216, -1728]));
    print(insertion_sort_desc([147, -21, -216, -1728]));
}
