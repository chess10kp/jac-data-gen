def get_last_two_chars(string: Any) -> object {
    if (len(string) < 2) {
        return 'zz';
    }
    return string[-2:];
}



with entry {
    print(get_last_two_chars('hello'));
    print(get_last_two_chars('Racecar'));
    print(get_last_two_chars('abcabc'));
}
