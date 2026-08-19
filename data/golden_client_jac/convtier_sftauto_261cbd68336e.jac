def decimal_to_binary(decimal: Any) -> object {
    if (decimal == 0) {
        return 0;
    }
    binary = 0;
    i = 0;
    while (decimal > 0) {
        remainder = decimal % 2;
        binary += remainder * (10 ** i);
        decimal //= 2;
        i += 1;
    }
    return binary;
}



with entry {
    print(decimal_to_binary(5));
    print(decimal_to_binary(10));
    print(decimal_to_binary(2));
}
