def replace_with_ascii(string: Any) -> object {
    result = "";
    for char in string {
        if char.islower() {
            result += str((ord(char) + 32));
        } elif char.isupper() {
            result += str((ord(char) - 32));
        } else {
            result += char;
        }
    }
    return result;
}



with entry {
    print(replace_with_ascii('hello'));
    print(replace_with_ascii('Racecar'));
    print(replace_with_ascii('abcabc'));
}
