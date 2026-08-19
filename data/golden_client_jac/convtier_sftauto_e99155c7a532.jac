def remove_and_count_chars(input_string: Any) -> object {
    input_string = input_string.strip();
    counts = {'a': 0, 'b': 0, 'c': 0};
    for char in input_string {
        if (char in ['a', 'b', 'c']) {
            input_string = input_string.replace(char, '', 1);
            counts[char] += 1;
        }
    }
    return counts;
}



with entry {
    print(remove_and_count_chars('hello'));
    print(remove_and_count_chars('Racecar'));
    print(remove_and_count_chars('abcabc'));
}
