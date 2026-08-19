def int_to_string(n: Any) -> object {
    if (n < 0) {
        return ('-' + int_to_string(-n));
    }
    if (n < 10) {
        return chr((ord('0') + n));
    }
    return (int_to_string((n // 10)) + chr((ord('0') + (n % 10))));
}



with entry {
    print(int_to_string(5));
    print(int_to_string(2));
    print(int_to_string(0));
}
