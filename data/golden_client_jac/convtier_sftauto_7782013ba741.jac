def merge_sort(strings: Any) -> object {
    if (len(strings) <= 1) {
        return strings;
    }
    mid = len(strings) // 2;
    left_half = strings[:mid];
    right_half = strings[mid:];
    sorted_left = merge_sort(left_half);
    sorted_right = merge_sort(right_half);
    return merge(sorted_left, sorted_right);
}



with entry {
    print(merge_sort([81]));
    print(merge_sort([]));
    print(merge_sort(['a']));
}
