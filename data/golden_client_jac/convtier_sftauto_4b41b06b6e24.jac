def sum_of_squares(numbers: Any) -> object {
    even_numbers = [
        num
        for num in numbers
        if (isinstance(num, int) and ((num % 2) == 0))
    ];
    filtered_numbers = [
        num
        for num in even_numbers
        if (0 <= num <= 10)
    ];
    squared_numbers = [(num ** 2) for num in filtered_numbers];
    return sum(squared_numbers);
}



with entry {
    print(sum_of_squares('hello'));
    print(sum_of_squares([6, -12]));
}
