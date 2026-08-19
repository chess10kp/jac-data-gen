def is_sorted(lst: Any) -> object {
    if (len(lst) <= 1) {
        return True;
    }
    mid = len(lst) // 2;
    left = lst[:mid];
    right = lst[mid:];
    return (is_sorted(left) and is_sorted(right) and (left[-1] <= right[0]));
}



with entry {
    print(is_sorted([81]));
}
