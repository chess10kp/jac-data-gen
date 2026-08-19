def is_num_even(num: Any) -> object {
    if not isinstance(num, (int, float)) {
        raise InvalidInputError("Input is not a number.");
    }
    if (num < 0) {
        raise InvalidInputError("Input is a negative number.");
    }
    num = int(num) if isinstance(num, float) else num;
    num = int(num);
    return ((num % 2) == 0);
}



with entry {
    print(is_num_even(5));
    print(is_num_even(10));
}
