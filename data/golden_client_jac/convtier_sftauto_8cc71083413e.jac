def to_uppercase(string: Any) -> object {
    uppercase_string = "";
    for char in string {
        if (ord('a') <= ord(char) <= ord('z')) {
            uppercase_char = chr((ord(char) - (ord('a') - ord('A'))));
        } else {
            uppercase_char = char;
        }
        uppercase_string += uppercase_char;
    }
    return uppercase_string;
}



with entry {
    print(to_uppercase('hello'));
    print(to_uppercase('Racecar'));
    print(to_uppercase('abcabc'));
}
