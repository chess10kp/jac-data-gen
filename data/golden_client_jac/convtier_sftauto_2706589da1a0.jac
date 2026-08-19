def remove_whitespace(string: Any) -> object {
    new_string = "";
    for char in string {
        if (char != " ") {
            new_string += char;
        }
    }
    return new_string;
}



with entry {
    print(remove_whitespace('hello'));
    print(remove_whitespace('Racecar'));
    print(remove_whitespace('abcabc'));
}
