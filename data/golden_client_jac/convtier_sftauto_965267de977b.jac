def double_and_filter(lst: Any) -> object {
    doubled_list = [(2 * x) for x in `set(lst)];
    result_list = [
        x
        for x in sorted(doubled_list, reverse=True)
        if ((x % 3) == 0)
    ];
    return result_list;
}



with entry {
    print(double_and_filter([81]));
    print(double_and_filter([]));
}
