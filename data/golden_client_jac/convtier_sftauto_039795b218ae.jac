def decimal_to_binary(decimal: Any) -> object {
    binary = bin(decimal)[2:];
    return binary;
}



with entry {
    print(decimal_to_binary(5));
    print(decimal_to_binary(10));
    print(decimal_to_binary(2));
}
