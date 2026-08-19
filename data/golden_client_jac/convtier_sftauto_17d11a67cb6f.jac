def convert_to_uppercase(string: Any) -> object {
    result = "";
    for char in string {
        if (ord('a') <= ord(char) <= ord('z')) {
            char = chr((ord(char) - 32));
        }
        result += char;
    }
    return result;
}



with entry {
    print(convert_to_uppercase('hello'));
    print(convert_to_uppercase('Racecar'));
    print(convert_to_uppercase('abcabc'));
}
