def base10_to_base16(num: Any) -> object {
    if (num == 0) {
        return '0';
    }
    hex_chars = "0123456789ABCDEF";
    result = "";
    while (num > 0) {
        remainder = num % 16;
        result = hex_chars[remainder] + result;
        num = num // 16;
    }
    return result;
}



with entry {
    print(base10_to_base16(5));
    print(base10_to_base16(10));
    print(base10_to_base16(2));
}
