def binary_representation(number: Any) -> object {
    binary = "";
    for i in range(31, -1, -1) {
        if (number & (1 << i)) {
            binary += '1';
        } else {
            binary += '0';
        }
    }
    return binary;
}



with entry {
    print(binary_representation(5));
    print(binary_representation(10));
    print(binary_representation(2));
}
