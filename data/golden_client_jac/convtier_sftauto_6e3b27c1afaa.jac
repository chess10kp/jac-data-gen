def count_digits(number: Any) -> object {
    number = `abs(number);
    num_digits = len(str(number));
    return num_digits;
}



with entry {
    print(count_digits(5));
    print(count_digits(10));
    print(count_digits(100));
}
