def convert_to_base16(number: Any) -> object {
    result = "";
    while (number > 0) {
        remainder = number % 16;
        result = str(remainder) + result;
        number = number // 16;
    }
    return result;
}



with entry {
    print(convert_to_base16(5));
    print(convert_to_base16(10));
    print(convert_to_base16(2));
}
