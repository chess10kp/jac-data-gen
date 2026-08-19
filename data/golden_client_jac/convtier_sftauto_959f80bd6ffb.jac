def remove_spaces(string: Any) -> object {
    return string.strip();
}



with entry {
    print(remove_spaces('hello'));
    print(remove_spaces('Racecar'));
    print(remove_spaces('abcabc'));
}
