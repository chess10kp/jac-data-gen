def find_max(lst: Any) -> object {
    if not lst {
        return None;
    }
    if (len(lst) == 1) {
        return lst[0];
    }
    mid = len(lst) // 2;
    left_max = find_max(lst[:mid]);
    right_max = find_max(lst[mid:]);
    if (left_max is None) {
        return right_max;
    } elif (right_max is None) {
        return left_max;
    } else {
        return max(left_max, right_max);
    }
}



with entry {
    print(find_max([2]));
    print(find_max([34]));
}
