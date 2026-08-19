def longest_string_with_letters(strings: Any) -> object {
    longest_string = '';
    for string in strings {
        if (`any(c.islower() for c in string) and `any(c.isupper() for c in string)) {
            if (len(string) > len(longest_string)) {
                longest_string = string;
            }
        }
    }
    return longest_string;
}



with entry {
    print(longest_string_with_letters('hello'));
}
