def calculate_median(numbers: Any) -> object {
    sorted_numbers = sorted(numbers);
    middle_index = (len(sorted_numbers) + 1) // 2;
    median = sorted_numbers[(middle_index - 1)];
    return median;
}



with entry {
    print(calculate_median('hello'));
    print(calculate_median('Racecar'));
    print(calculate_median('abcabc'));
}
