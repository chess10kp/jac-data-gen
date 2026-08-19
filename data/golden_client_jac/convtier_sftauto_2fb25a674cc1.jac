def decimal_to_binary(n: Any) -> object {
    if (n == 0) {
        return '0';
    }
    binary = '';
    while (n > 0) {
        binary = str((n % 2)) + binary;
        n //= 2;
    }
    return binary;
}



with entry {
    print(decimal_to_binary(5));
    print(decimal_to_binary(10));
    print(decimal_to_binary(2));
}
