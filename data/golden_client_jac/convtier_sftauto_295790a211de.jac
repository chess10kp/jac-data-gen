def decimal_to_binary(num: Any) -> object {
    if (num == 0) {
        return '0';
    } elif (num < 0) {
        num = (1 << 32) + num;
    }
    binary = '';
    while (num > 0) {
        binary = str((num % 2)) + binary;
        num >>= 1;
    }
    return binary;
}



with entry {
    print(decimal_to_binary(5));
    print(decimal_to_binary(10));
    print(decimal_to_binary(2));
}
