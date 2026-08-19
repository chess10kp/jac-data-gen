def float_to_binary(number: Any) -> object {
    rounded_number = round(number, 4);
    binary_number = bin(rounded_number)[2:];
    if (len(binary_number) < 12) {
        binary_number = ('0' * (12 - len(binary_number))) + binary_number;
    }
    return binary_number;
}



with entry {
    print(float_to_binary(5));
    print(float_to_binary(10));
    print(float_to_binary(2));
}
