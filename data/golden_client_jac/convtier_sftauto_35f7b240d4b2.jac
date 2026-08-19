def weighted_average(lst: Any) -> object {
    flattened_lst = [item for sublist in lst for item in sublist]
        if `any(isinstance(item, `list) for item in lst)
        else lst;
    index_sum = sum(range(len(flattened_lst)));
    if (index_sum == 0) {
        return 0;
    }
    weighted_sum = sum((i * num) for (i, num) in enumerate(flattened_lst));
    weighted_average = weighted_sum / index_sum;
    return round(weighted_average, 2);
}



with entry {
    print(weighted_average([]));
    print(weighted_average([-12, 6]));
    print(weighted_average([-12, -6, -3, 21]));
}
