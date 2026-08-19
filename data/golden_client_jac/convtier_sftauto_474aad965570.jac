def insertion_sort_descending(arr: Any) -> object {
    n = len(arr);
    for i in range(1, n) {
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
    print(insertion_sort_descending([4, 2, 1]));
    print(insertion_sort_descending([2, 1]));
    print(insertion_sort_descending([5, 5, 5]));
}
