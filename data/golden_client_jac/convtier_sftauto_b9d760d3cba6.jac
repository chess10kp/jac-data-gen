def sum_of_lists(lists: Any) -> object {
    total_sum = 0;
    for lst in lists {
        if isinstance(lst, `list) {
            total_sum += sum_of_lists(lst);
        } else {
            total_sum += lst;
        }
    }
    return total_sum;
}



with entry {
    print(sum_of_lists([]));
    print(sum_of_lists([6, -12]));
}
