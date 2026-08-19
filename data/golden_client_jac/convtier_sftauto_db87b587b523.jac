def convert_to_uppercase(s: Any) -> object {
    result = '';
    for c in s {
        if ('a' <= c <= 'z') {
            result += chr((ord(c) - 32));
        } else {
            result += c;
        }
    }
    return result;
}



with entry {
    print(convert_to_uppercase('hello'));
    print(convert_to_uppercase('Racecar'));
    print(convert_to_uppercase('abcabc'));
}
