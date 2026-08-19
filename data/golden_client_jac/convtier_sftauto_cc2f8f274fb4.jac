def get_first_two_characters(s: Any) -> object {
    return s[:2];
}



with entry {
    print(get_first_two_characters('hello'));
    print(get_first_two_characters('Racecar'));
    print(get_first_two_characters('abcabc'));
}
