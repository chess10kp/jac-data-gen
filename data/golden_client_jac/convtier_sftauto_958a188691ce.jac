def calculate_frequency(word: Any) -> object {
    frequency = 0;
    for char in word {
        bit_index = ord(char) - ord('a');
        frequency |= 1 << bit_index;
    }
    return frequency;
}



with entry {
    print(calculate_frequency('hello'));
    print(calculate_frequency('abcabc'));
    print(calculate_frequency('level'));
}
