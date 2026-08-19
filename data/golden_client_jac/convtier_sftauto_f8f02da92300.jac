def convert_case(s: Any) -> object {
    converted = "";
    for char in s {
        ascii_val = ord(char);
        if (65 <= ascii_val <= 90) {
            converted += chr((ascii_val + 32));
        } elif (97 <= ascii_val <= 122) {
            converted += chr((ascii_val - 32));
        } else {
            converted += char;
        }
    }
    return converted;
}



with entry {
    print(convert_case('hello'));
    print(convert_case('Racecar'));
    print(convert_case('abcabc'));
}
