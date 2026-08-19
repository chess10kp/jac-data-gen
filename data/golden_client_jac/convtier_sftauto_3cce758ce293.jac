def merge_sort(array: Any) -> object {
    if (len(array) <= 1) {
        return array;
    }
    mid = len(array) // 2;
    left_half = array[:mid];
    right_half = array[mid:];
    left_half = merge_sort(left_half);
    right_half = merge_sort(right_half);
    return merge(left_half, right_half);
}



with entry {
    print(merge_sort([81]));
    print(merge_sort([]));
    print(merge_sort(['a']));
}
