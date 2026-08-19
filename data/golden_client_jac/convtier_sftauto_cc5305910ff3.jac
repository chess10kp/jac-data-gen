def modified_insertion_sort(arr: Any) -> object {
    for i in range(1, len(arr)) {
        current = arr[i];
        j = i - 1;
        while ((j >= 0) and (current > arr[j])) {
            arr[(j + 1)] = arr[j];
            j -= 1;
        }
        arr[(j + 1)] = current;
    }
    return arr;
}



with entry {
    print(modified_insertion_sort([4, 2, 1]));
    print(modified_insertion_sort([2, 1]));
    print(modified_insertion_sort([5, 5]));
}
