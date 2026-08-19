def merge_sort(my_list: Any) -> object {
    if (len(my_list) <= 1) {
        return my_list;
    }
    mid = len(my_list) // 2;
    left_half = my_list[:mid];
    right_half = my_list[mid:];
    left_half = merge_sort(left_half);
    right_half = merge_sort(right_half);
    return merge(left_half, right_half);
}



with entry {
    print(merge_sort([]));
}
