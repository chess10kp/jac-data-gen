def get_median(numbers: Any) -> object {
    sorted_numbers = sorted(numbers);
    length = len(sorted_numbers);
    middle_index = length // 2;
    if ((length % 2) == 0) {
        median = (
            (sorted_numbers[(middle_index - 1)] + sorted_numbers[middle_index]) / 2
        );
    } else {
        median = sorted_numbers[middle_index];
    }
    return median;
}



with entry {
    print(get_median('hello'));
    print(get_median('Racecar'));
    print(get_median('Hello, World!'));
}
