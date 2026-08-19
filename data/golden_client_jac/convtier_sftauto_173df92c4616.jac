def count_characters(string: Any) -> object {
    char_counts = {};
    for char in string {
        if (char in char_counts) {
            char_counts[char] += 1;
        } else {
            char_counts[char] = 1;
        }
    }
    return char_counts;
}



with entry {
    print(count_characters('hello'));
    print(count_characters('Racecar'));
    print(count_characters('abcabc'));
}
