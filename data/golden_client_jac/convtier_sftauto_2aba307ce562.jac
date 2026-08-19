def merge_sort(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    }
    mid = len(arr) // 2;
    left_half = arr[:mid];
    right_half = arr[mid:];
    merge_sort(left_half);
    merge_sort(right_half);
    merge(arr, left_half, right_half);
}



with entry {
    print(merge_sort([81]));
    print(merge_sort([]));
    print(merge_sort(['a']));
}
