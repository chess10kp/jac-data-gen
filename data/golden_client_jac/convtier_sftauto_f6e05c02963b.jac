def sort_and_sum(lst: Any) -> object {
    sorted_lst = sorted(lst, reverse=True);
    filtered_lst = [
        num
        for num in sorted_lst
        if ((num % 2) != 0)
    ];
    total_sum = sum(filtered_lst);
    return total_sum;
}



with entry {
    print(sort_and_sum([]));
}
