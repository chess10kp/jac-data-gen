def mergeSort(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    }
    mid = len(arr) // 2;
    left = mergeSort(arr[:mid]);
    right = mergeSort(arr[mid:]);
    return merge(left, right);
}



with entry {
    print(mergeSort([-9]));
    print(mergeSort([]));
}
