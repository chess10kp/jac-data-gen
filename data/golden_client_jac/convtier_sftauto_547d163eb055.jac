def find_median(arr: Any) -> object {
    sorted_arr = sorted(arr);
    n = len(sorted_arr);
    if ((n % 2) == 0) {
        return ((sorted_arr[(n // 2)] + sorted_arr[((n // 2) - 1)]) / 2);
    } else {
        return sorted_arr[(n // 2)];
    }
}



with entry {
    print(find_median('hello'));
    print(find_median('Racecar'));
    print(find_median('Hello, World!'));
}
