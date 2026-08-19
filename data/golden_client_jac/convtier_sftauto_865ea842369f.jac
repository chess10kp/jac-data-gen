def insertion_sort(arr: Any) -> object {
    for i in range(1, len(arr)) {
        key = arr[i];
        j = i - 1;
        while (
            (j >= 0)
            and (
                (len(arr[j]) < len(key))
                or ((len(arr[j]) == len(key)) and (arr[j] < key))
            )
        ) {
            arr[(j + 1)] = arr[j];
            j = j - 1;
        }
        arr[(j + 1)] = key;
    }
    return arr;
}



with entry {
    print(insertion_sort([]));
}
