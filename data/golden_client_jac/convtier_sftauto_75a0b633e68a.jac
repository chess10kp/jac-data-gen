def decimal_to_octal(decimal: Any) -> object {
    if (decimal == 0) {
        return 0;
    }
    result = 0;
    power = 1;
    while (decimal != 0) {
        result |= (decimal & 7) * power;
        decimal >>= 3;
        power *= 10;
    }
    return result;
}



with entry {
    print(decimal_to_octal(5));
    print(decimal_to_octal(10));
    print(decimal_to_octal(2));
}
