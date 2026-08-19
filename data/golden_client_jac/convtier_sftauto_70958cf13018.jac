def to_lower_case(s: Any) -> object {
    result = "";
    for char in s {
        if ('A' <= char <= 'Z') {
            result += chr((ord(char) + 32));
        } else {
            result += char;
        }
    }
    return result;
}



with entry {
    print(to_lower_case('hello'));
    print(to_lower_case('Racecar'));
    print(to_lower_case('abcabc'));
}
