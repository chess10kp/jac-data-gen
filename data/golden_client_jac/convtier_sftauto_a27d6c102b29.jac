def hex_to_binary(hex_num: Any) -> object {
    binary_num = 0;
    for char in hex_num {
        decimal_value = ((ord(char) - ord('A')) + 10) if char.isalpha() else int(char);
        binary_num = (binary_num << 4) | decimal_value;
    }
    return bin(binary_num)[2:];
}



with entry {
    print(hex_to_binary('hello'));
    print(hex_to_binary('Racecar'));
    print(hex_to_binary('abcabc'));
}
