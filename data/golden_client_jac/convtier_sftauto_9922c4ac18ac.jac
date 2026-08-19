def decimal_to_binary(number: Any) -> object {
    binary = "";
    while (number > 0) {
        binary = str((number % 2)) + binary;
        number = number // 2;
    }
    return binary;
}



with entry {
    print(decimal_to_binary(5));
    print(decimal_to_binary(10));
    print(decimal_to_binary(2));
}
