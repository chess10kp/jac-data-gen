def find_longest_string(strings: Any) -> object {
    longest = "";
    for string in strings {
        length = 0;
        for char in string {
            length += 1;
        }
        if (length > len(longest)) {
            longest = string;
        }
    }
    return longest;
}



with entry {
    print(find_longest_string('hello'));
    print(find_longest_string('Racecar'));
    print(find_longest_string('abcabc'));
}
