def replace_spaces(string: Any) -> object {
    string = string.strip();
    words = string.split();
    return '_'.join(words);
}



with entry {
    print(replace_spaces('hello'));
    print(replace_spaces('Racecar'));
    print(replace_spaces('abcabc'));
}
