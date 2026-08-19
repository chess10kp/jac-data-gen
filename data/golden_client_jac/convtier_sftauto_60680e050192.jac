def recursive_sum(lst: Any) -> object {
    if not lst {
        return 0;
    }
    if (len(lst) == 1) {
        return lst[0];
    }
    return (lst[0] + recursive_sum(lst[1:]));
}



with entry {
    print(recursive_sum(0));
}
