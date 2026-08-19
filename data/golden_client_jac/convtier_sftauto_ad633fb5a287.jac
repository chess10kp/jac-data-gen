def find_longest_string(strings: Any) -> object {
    longest_string = None;
    max_length = 0;
    for string in strings {
        if (len(string) > max_length) {
            longest_string = string;
            max_length = len(string);
        }
    }
    return longest_string;
}



with entry {
    print(find_longest_string('hello'));
    print(find_longest_string('Racecar'));
    print(find_longest_string('abcabc'));
}
