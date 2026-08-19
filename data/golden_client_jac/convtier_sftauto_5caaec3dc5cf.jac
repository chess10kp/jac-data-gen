def count_chars(input_string: Any) -> object {
    char_counts = {};
    for (i, char) in enumerate(input_string) {
        if (char.isalpha() and not char.isspace()) {
            char = char.lower();
            if (char in char_counts) {
                char_counts[char]['count'] += 1;
                char_counts[char]['positions'].append(i);
            } else {
                char_counts[char] = {'count': 1, 'positions': [i]};
            }
        }
    }
    return char_counts;
}



with entry {
    print(count_chars('hello'));
    print(count_chars('Racecar'));
    print(count_chars('abcabc'));
}
