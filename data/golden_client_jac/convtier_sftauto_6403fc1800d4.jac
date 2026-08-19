def filter_and_sum(numbers: Any) -> object {
    filtered_numbers = [];
    for num in numbers {
        if (((num % 2) == 0) and ((num % 3) == 0) and ('5' in str(num))) {
            filtered_numbers.append(num);
        }
    }
    return sum(filtered_numbers);
}



with entry {
    print(filter_and_sum([]));
}
