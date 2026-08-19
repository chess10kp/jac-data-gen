def decimal_to_binary(decimal: Any) -> object {
    if (decimal == 0) {
        return '0';
    }
    binary = '';
    while (decimal > 0) {
        remainder = decimal % 2;
        binary += str(remainder);
        decimal //= 2;
    }
    return binary[::-1];
}



with entry {
    print(decimal_to_binary(5));
    print(decimal_to_binary(10));
    print(decimal_to_binary(2));
}
