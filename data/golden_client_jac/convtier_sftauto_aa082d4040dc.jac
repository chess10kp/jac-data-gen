def calculate_median(lst: Any) -> object {
    sorted_list = sorted(lst);
    n = len(sorted_list);
    mid = n // 2;
    if ((n % 2) == 0) {
        median = (sorted_list[(mid - 1)] + sorted_list[mid]) / 2;
    } else {
        median = sorted_list[mid];
    }
    return median;
}



with entry {
    print(calculate_median('hello'));
    print(calculate_median('Racecar'));
    print(calculate_median('Hello, World!'));
}
