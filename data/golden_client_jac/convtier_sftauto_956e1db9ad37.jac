def decimal_to_binary(n: Any) -> object {
    binary_rep = "";
    for i in range(7, -1, -1) {
        bit = (n >> i) & 1;
        binary_rep += str(bit);
    }
    return binary_rep;
}



with entry {
    print(decimal_to_binary(5));
    print(decimal_to_binary(10));
    print(decimal_to_binary(2));
}
