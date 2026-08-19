def max_binary_value(binary_string: Any) -> object {
    if `any((char not in '01') for char in binary_string) {
        raise ValueError(
            "Invalid binary string: characters other than '0' and '1' found."
        );
    }
    return max(map(int, binary_string), `default=0);
}



with entry {
    print(max_binary_value([]));
}
