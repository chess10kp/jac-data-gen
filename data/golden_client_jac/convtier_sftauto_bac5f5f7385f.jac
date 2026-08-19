def sum_of_numbers(strings: Any) -> object {
    total = 0;
    for string in strings {
        try {
            total += int(string);
        } except ValueError {
            raise CustomException(f"Invalid input: {string} is not a number");
        }
    }
    return total;
}



with entry {
    print(sum_of_numbers([81]));
    print(sum_of_numbers([]));
    print(sum_of_numbers([100]));
}
