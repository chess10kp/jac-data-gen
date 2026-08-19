def sum_of_squares(numbers: Any) -> object {
    sum = 0;
    for num in numbers {
        if (not isinstance(num, int) or (num < 1) or (num > 100)) {
            raise ValueError(
                "Invalid input. The list should only contain positive integers less than or equal to 100."
            );
        }
        sum += num ** 2;
    }
    return sum;
}



with entry {
    print(sum_of_squares([2, 9]));
    print(sum_of_squares([2]));
    print(sum_of_squares([34]));
}
