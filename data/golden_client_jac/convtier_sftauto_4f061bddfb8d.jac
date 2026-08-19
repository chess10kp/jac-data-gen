def merge_sort(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    }
    mid = len(arr) // 2;
    left = arr[:mid];
    right = arr[mid:];
    left_sorted = merge_sort(left);
    right_sorted = merge_sort(right);
    return merge(left_sorted, right_sorted);
}



with entry {
    print(merge_sort([]));
}
