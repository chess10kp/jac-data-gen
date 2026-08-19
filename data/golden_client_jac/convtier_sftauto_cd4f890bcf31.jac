def find_longest_substring(string: Any) -> object {
    vowels = {'a', 'e', 'i', 'o', 'u'};
    longest_substring = "";
    current_substring = "";
    for char in string {
        if (char in vowels) {
            current_substring = char;
            for next_char in string[(string.index(char) + 1):] {
                if (next_char in current_substring) {
                    break;
                }
                current_substring += next_char;
            }
            if (len(current_substring) > len(longest_substring)) {
                longest_substring = current_substring;
            }
        }
    }
    return longest_substring;
}



with entry {
    print(find_longest_substring('hello'));
    print(find_longest_substring('Racecar'));
    print(find_longest_substring('abcabc'));
}
