def sum_of_list(lst: Any) -> object {
    if (len(lst) == 0) {
        return 0;
    } else {
        return (lst[0] + sum_of_list(lst[1:]));
    }
}



with entry {
    print(sum_of_list([]));
}
