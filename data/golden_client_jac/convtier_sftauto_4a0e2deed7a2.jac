def merge_sort_descending(arr: Any) -> object {
    if (len(arr) <= 1) {
        return arr;
    }
    mid = len(arr) // 2;
    left = merge_sort_descending(arr[:mid]);
    right = merge_sort_descending(arr[mid:]);
    return merge(left, right);
}



with entry {
    print(merge_sort_descending([2]));
    print(merge_sort_descending([34]));
}
