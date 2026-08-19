def merge_sort_descending(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    }
    mid = len(arr) // 2;
    left_half = arr[:mid];
    right_half = arr[mid:];
    left_half = merge_sort_descending(left_half);
    right_half = merge_sort_descending(right_half);
    return merge(left_half, right_half);
}



with entry {
    print(merge_sort_descending([]));
}
