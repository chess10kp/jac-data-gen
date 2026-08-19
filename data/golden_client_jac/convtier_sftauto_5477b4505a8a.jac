def remove_whitespaces(string: Any) -> object {
    string = string.strip();
    string = ''.join(string.split());
    return string;
}



with entry {
    print(remove_whitespaces('hello'));
    print(remove_whitespaces('Racecar'));
    print(remove_whitespaces('abcabc'));
}
