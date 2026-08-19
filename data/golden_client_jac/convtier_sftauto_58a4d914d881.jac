def convert_hex_to_rgb(hex_code: Any) -> object {
    if (
        (len(hex_code) != 6)
        or not all((c.isdigit() or (c.lower() in 'abcdef')) for c in hex_code)
    ) {
        return 'Invalid hexadecimal color code';
    }
    r = int(hex_code[0:2], 16);
    g = int(hex_code[2:4], 16);
    b = int(hex_code[4:6], 16);
    rgb_format = f"RGB({r}, {g}, {b})";
    return rgb_format;
}



with entry {
    print(convert_hex_to_rgb('hello'));
    print(convert_hex_to_rgb('abcabc'));
}
