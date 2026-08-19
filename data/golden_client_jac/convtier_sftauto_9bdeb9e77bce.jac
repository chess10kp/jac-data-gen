def format_numbers(numbers: Any) -> object {
    formatted_numbers = [];
    for number in numbers {
        formatted_number = "{:,.2f}".format(round(number, 2));
        formatted_numbers.append(formatted_number);
    }
    return formatted_numbers;
}



with entry {
    print(format_numbers([]));
}
