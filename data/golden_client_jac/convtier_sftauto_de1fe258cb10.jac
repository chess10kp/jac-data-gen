def count_characters(input_string: Any) -> object {
    character_counts = {};
    for char in input_string {
        if (char in character_counts) {
            character_counts[char] += 1;
        } else {
            character_counts[char] = 1;
        }
    }
    return character_counts;
}



with entry {
    print(count_characters('hello'));
    print(count_characters('Racecar'));
    print(count_characters('abcabc'));
}
