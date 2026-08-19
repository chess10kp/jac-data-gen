def filter_numbers(numbers: Any) -> object {
    filtered_numbers = [];
    for number in numbers {
        if ((number % 3) != 0) {
            filtered_numbers.append(number);
        }
    }
    return filtered_numbers;
}



with entry {
    print(filter_numbers([]));
}
