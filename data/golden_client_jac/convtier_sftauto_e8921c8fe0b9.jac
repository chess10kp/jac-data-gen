def get_first_two_chars(s: Any) -> object {
    if (len(s) < 2) {
        return s;
    }
    first_two = s[0] + s[1];
    return first_two;
}



with entry {
    print(get_first_two_chars('hello'));
    print(get_first_two_chars('Racecar'));
    print(get_first_two_chars('abcabc'));
}
