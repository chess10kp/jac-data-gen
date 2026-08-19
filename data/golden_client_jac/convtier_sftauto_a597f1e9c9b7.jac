def reverse_list(lst: Any) -> object {
    left = 0;
    right = len(lst) - 1;
    while (left < right) {
        (lst[left], lst[right]) = (lst[right], lst[left]);
        left += 1;
        right -= 1;
    }
    return lst;
}



with entry {
    print(reverse_list([81]));
    print(reverse_list([]));
    print(reverse_list(['a']));
}
