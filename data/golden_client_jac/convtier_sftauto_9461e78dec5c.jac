def longest_substring(string: Any) -> object {
    longest = '';
    current = '';
    for char in string {
        if (char in current) {
            if (len(current) > len(longest)) {
                longest = current;
            }
            current = '';
        }
        current += char;
    }
    if (len(current) > len(longest)) {
        longest = current;
    }
    return longest;
}



with entry {
    print(longest_substring('hello'));
    print(longest_substring('Racecar'));
    print(longest_substring('abcabc'));
}
