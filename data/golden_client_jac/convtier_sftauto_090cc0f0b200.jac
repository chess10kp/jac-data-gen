def reverse_list(lst: Any) -> object {
    if (len(lst) <= 1) {
        return lst;
    }
    return (reverse_list(lst[1:]) + [lst[0]]);
}



with entry {
    print(reverse_list([81]));
    print(reverse_list([]));
    print(reverse_list(['a']));
}
