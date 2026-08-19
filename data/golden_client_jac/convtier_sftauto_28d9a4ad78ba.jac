def find_median(lst: Any) -> object {
    sorted_lst = sorted(lst);
    n = len(sorted_lst);
    if ((n % 2) == 0) {
        median = (sorted_lst[((n // 2) - 1)] + sorted_lst[(n // 2)]) / 2;
    } else {
        median = sorted_lst[(n // 2)];
    }
    return median;
}



with entry {
    print(find_median('hello'));
    print(find_median('Racecar'));
    print(find_median('Hello, World!'));
}
