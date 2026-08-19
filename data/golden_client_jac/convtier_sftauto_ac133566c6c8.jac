def get_odd_numbers(input_list: Any) -> object {
    if not input_list {
        return "Input list is empty.";
    }
    odd_numbers = [];
    for num in input_list {
        if ((num % 2) != 0) {
            odd_numbers.append(num);
        }
    }
    return odd_numbers;
}



with entry {
    print(get_odd_numbers(0));
    print(get_odd_numbers([-12, 6]));
    print(get_odd_numbers([-12, -6, -3, 21]));
}
