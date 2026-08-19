def convert_to_uppercase(string: Any) -> object {
    uppercase_string = "";
    for char in string {
        if ((ord(char) >= 97) and (ord(char) <= 122)) {
            uppercase_string += chr((ord(char) - 32));
        } else {
            uppercase_string += char;
        }
    }
    return uppercase_string;
}



with entry {
    print(convert_to_uppercase('hello'));
    print(convert_to_uppercase('Racecar'));
    print(convert_to_uppercase('abcabc'));
}
