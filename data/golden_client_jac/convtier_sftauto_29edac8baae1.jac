def count_chars(input_string: str) -> dict {
    char_count = {};
    for char in input_string {
        if (char in char_count) {
            char_count[char] += 1;
        } else {
            char_count[char] = 1;
        }
    }
    return char_count;
}



with entry {
    print(count_chars('hello'));
    print(count_chars('Racecar'));
    print(count_chars('abcabc'));
}
