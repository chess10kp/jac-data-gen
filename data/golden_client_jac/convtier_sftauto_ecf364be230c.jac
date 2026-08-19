def is_num_even(number: Any) -> object {
    if not isinstance(number, (int, float)) {
        raise InvalidInputError("Input must be a number");
    }
    return ((number % 2) == 0);
}



with entry {
    print(is_num_even(5));
    print(is_num_even(10));
}
