def shuffle_list(lst: Any) -> object {
    n = len(lst);
    for i in range((n - 1), 0, -1) {
        j = random.randint(0, i);
        (lst[i], lst[j]) = (lst[j], lst[i]);
    }
    return sorted(lst);
}



with entry {
    print(shuffle_list([81]));
    print(shuffle_list([]));
    print(shuffle_list(['a']));
}
