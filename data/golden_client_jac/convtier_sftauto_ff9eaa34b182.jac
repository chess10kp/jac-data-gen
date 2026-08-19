def sum_of_squares_of_even_numbers(lst: Any) -> object {
    sum_of_squares = 0;
    for num in lst {
        if ((num % 2) == 0) {
            square = num * num;
            sum_of_squares += square;
        }
    }
    return sum_of_squares;
}



with entry {
    print(sum_of_squares_of_even_numbers([]));
}
