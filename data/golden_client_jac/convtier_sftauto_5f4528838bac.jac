def merge_sort(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    }
    mid = len(arr) // 2;
    left = arr[:mid];
    right = arr[mid:];
    merge_sort(left);
    merge_sort(right);
    merge(left, right, arr);
}



with entry {
    print(merge_sort([-9]));
    print(merge_sort([]));
}
