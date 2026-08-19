def round_decimal(number: Any) -> object {
    rounded_number = round(number);
    return rounded_number;
}



with entry {
    print(round_decimal(5));
    print(round_decimal(10));
    print(round_decimal(2));
}
