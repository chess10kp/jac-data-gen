def insertionSort(arr: Any) -> object {
    for i in range(1, len(arr)) {
        key = arr[i];
        j = i - 1;
        while ((j >= 0) and (arr[j] > key)) {
            arr[(j + 1)] = arr[j];
            j = j - 1;
        }
        arr[(j + 1)] = key;
    }
    return arr;
}



with entry {
    print(insertionSort([1, 2, 4]));
    print(insertionSort([1, 2]));
    print(insertionSort([5, 5]));
}
