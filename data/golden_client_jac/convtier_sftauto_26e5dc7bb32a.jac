def reverse_list(lst: Any) -> object {
    start = 0;
    end = len(lst) - 1;
    while (start < end) {
        (lst[start], lst[end]) = (lst[end], lst[start]);
        start += 1;
        end -= 1;
    }
    return lst;
}



with entry {
    print(reverse_list([-9]));
    print(reverse_list([]));
    print(reverse_list(['a', 'a']));
}
