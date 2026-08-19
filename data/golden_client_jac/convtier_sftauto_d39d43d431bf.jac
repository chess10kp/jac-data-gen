def format_numbers(numbers: Any) -> object {
    rounded_numbers = [round(num, 3) for num in numbers];
    formatted_numbers = ["{:.5f}".format(num) for num in rounded_numbers];
    sorted_numbers = sorted(formatted_numbers);
    return sorted_numbers;
}



with entry {
    print(format_numbers([81]));
    print(format_numbers([]));
    print(format_numbers([100]));
}
