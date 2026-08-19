def count_characters(string: Any) -> object {
    frequencies = {};
    for char in string {
        if char.isalpha() {
            char = char.lower();
            if (char in frequencies) {
                frequencies[char] += 1;
            } else {
                frequencies[char] = 1;
            }
        }
    }
    return frequencies;
}



with entry {
    print(count_characters('hello'));
    print(count_characters('Racecar'));
    print(count_characters('abcabc'));
}
