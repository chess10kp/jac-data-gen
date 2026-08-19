def calculate_median(numbers: Any) -> object {
    sorted_numbers = sorted(numbers);
    n = len(sorted_numbers);
    middle_index = n // 2;
    if ((n % 2) == 1) {
        median = sorted_numbers[middle_index];
    } else {
        median = (
            (sorted_numbers[(middle_index - 1)] + sorted_numbers[middle_index]) / 2
        );
    }
    return median;
}



with entry {
    print(calculate_median('hello'));
    print(calculate_median('Racecar'));
    print(calculate_median('Hello, World!'));
}
