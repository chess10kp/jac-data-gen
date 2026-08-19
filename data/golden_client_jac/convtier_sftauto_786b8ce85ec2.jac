def count_characters(input_string: Any) -> object {
    character_count = {};
    for char in input_string {
        if (char in character_count) {
            character_count[char] += 1;
        } else {
            character_count[char] = 1;
        }
    }
    return character_count;
}



with entry {
    print(count_characters('hello'));
    print(count_characters('Racecar'));
    print(count_characters('abcabc'));
}
