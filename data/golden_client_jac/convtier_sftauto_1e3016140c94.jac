def convert_to_uppercase(string: Any) -> object {
    result = "";
    for char in string {
        if (char.isalpha() and not char.isupper()) {
            result += char.upper();
        }
    }
    return result;
}



with entry {
    print(convert_to_uppercase('hello'));
    print(convert_to_uppercase('Racecar'));
    print(convert_to_uppercase('abcabc'));
}
