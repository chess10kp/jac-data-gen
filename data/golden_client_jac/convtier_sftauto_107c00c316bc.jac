def merge_sort(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    }
    mid = len(arr) // 2;
    left = arr[:mid];
    right = arr[mid:];
    merge_sort(left);
    merge_sort(right);
    merge(arr, left, right);
}



with entry {
    print(merge_sort([81]));
    print(merge_sort([]));
    print(merge_sort(['a']));
}
