def decimal_to_binary(num: Any) -> object {
    binary = "";
    for i in range(31, -1, -1) {
        shifted_value = num >> i;
        if (shifted_value & 1) {
            binary += '1';
        } else {
            binary += '0';
        }
    }
    return binary;
}



with entry {
    print(decimal_to_binary(5));
    print(decimal_to_binary(10));
    print(decimal_to_binary(2));
}
