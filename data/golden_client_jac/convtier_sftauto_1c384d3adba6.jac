def decimal_to_octal(n: Any) -> object {
    if (n == 0) {
        return '0';
    }
    result = '';
    while (n > 0) {
        remainder = n % 8;
        result = str(remainder) + result;
        n = n // 8;
    }
    return result;
}



with entry {
    print(decimal_to_octal(5));
    print(decimal_to_octal(10));
    print(decimal_to_octal(2));
}
