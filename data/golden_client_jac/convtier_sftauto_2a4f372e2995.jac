def convert_to_ascii(string: Any) -> object {
    result = [];
    encoded_string = string.encode('utf-8');
    for byte in encoded_string {
        result.append(byte);
    }
    return result;
}



with entry {
    print(convert_to_ascii('hello'));
    print(convert_to_ascii('Racecar'));
    print(convert_to_ascii('abcabc'));
}
