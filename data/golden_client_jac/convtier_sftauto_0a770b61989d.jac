def convert_to_hex(string: Any) -> object {
    if (len(string) == 0) {
        return "";
    }
    hex_code = "".join([hex(ord(c))[2:] for c in string]);
    return hex_code;
}



with entry {
    print(convert_to_hex('hello'));
    print(convert_to_hex('Racecar'));
    print(convert_to_hex('abcabc'));
}
