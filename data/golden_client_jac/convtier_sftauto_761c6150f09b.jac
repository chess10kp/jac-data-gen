def convert_to_uppercase(s: Any) -> object {
    upper_s = "";
    for char in s {
        ascii_value = ord(char);
        if (97 <= ascii_value <= 122) {
            upper_s += chr((ascii_value - 32));
        } else {
            upper_s += char;
        }
    }
    return upper_s;
}



with entry {
    print(convert_to_uppercase('hello'));
    print(convert_to_uppercase('Racecar'));
    print(convert_to_uppercase('abcabc'));
}
