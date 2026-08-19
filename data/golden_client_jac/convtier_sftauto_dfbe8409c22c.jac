def remove_whitespace(string: Any) -> object {
    result = string.replace(" ", "");
    return result;
}



with entry {
    print(remove_whitespace('hello'));
    print(remove_whitespace('Racecar'));
    print(remove_whitespace('abcabc'));
}
