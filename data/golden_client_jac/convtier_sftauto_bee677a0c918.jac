def count_characters(string: Any) -> object {
    char_count = {};
    for char in string {
        if (char in char_count) {
            char_count[char] += 1;
        } else {
            char_count[char] = 1;
        }
    }
    return char_count;
}



with entry {
    print(count_characters('hello'));
    print(count_characters('Racecar'));
    print(count_characters('abcabc'));
}
