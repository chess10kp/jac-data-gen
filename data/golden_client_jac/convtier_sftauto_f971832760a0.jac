def string_to_hexadecimal(string: Any) -> object {
    if (string == "") {
        return "";
    }
    hexadecimal_code = "";
    for char in string {
        hexadecimal_code += hex(ord(char))[2:];
    }
    return hexadecimal_code;
}



with entry {
    print(string_to_hexadecimal('hello'));
    print(string_to_hexadecimal('Racecar'));
    print(string_to_hexadecimal('abcabc'));
}
