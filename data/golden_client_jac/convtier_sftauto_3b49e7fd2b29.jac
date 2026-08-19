def compute_median(lst: Any) -> object {
    sorted_lst = sorted(lst);
    n = len(sorted_lst);
    if ((n % 2) == 0) {
        median = (sorted_lst[((n // 2) - 1)] + sorted_lst[(n // 2)]) / 2;
    } else {
        median = sorted_lst[(n // 2)];
    }
    return "{:.2f}".format(median);
}



with entry {
    print(compute_median([2, -9]));
    print(compute_median([2]));
    print(compute_median([34]));
}
