def get_unique_elements(numbers: Any) -> object {
    unique_numbers = [];
    for number in numbers {
        if (number not in unique_numbers) {
            unique_numbers.append(number);
        }
    }
    return unique_numbers;
}



with entry {
    print(get_unique_elements('hello'));
    print(get_unique_elements('Racecar'));
    print(get_unique_elements('abcabc'));
}
