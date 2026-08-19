def decimal_to_binary(decimal_number: Any) -> object {
    binary = "";
    while (decimal_number > 0) {
        if (decimal_number & 1) {
            binary += '1';
        } else {
            binary += '0';
        }
        decimal_number >>= 1;
    }
    return binary[::-1];
}



with entry {
    print(decimal_to_binary(5));
    print(decimal_to_binary(10));
    print(decimal_to_binary(2));
}
