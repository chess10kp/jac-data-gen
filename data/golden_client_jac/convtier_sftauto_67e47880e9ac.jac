def find_median(numbers: Any) -> object {
    sorted_numbers = sorted(numbers);
    n = len(sorted_numbers);
    if ((n % 2) == 0) {
        median = (sorted_numbers[((n // 2) - 1)] + sorted_numbers[(n // 2)]) / 2;
    } else {
        median = sorted_numbers[(n // 2)];
    }
    return median;
}



with entry {
    print(find_median('hello'));
    print(find_median('Racecar'));
    print(find_median('Hello, World!'));
}
