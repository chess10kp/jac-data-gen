def merge_sort(lst: Any) -> object {
    if (len(lst) <= 1) {
        return lst;
    }
    mid = len(lst) // 2;
    left_half = lst[:mid];
    right_half = lst[mid:];
    left_half = merge_sort(left_half);
    right_half = merge_sort(right_half);
    return merge(left_half, right_half);
}



with entry {
    print(merge_sort([2]));
    print(merge_sort([34]));
}
