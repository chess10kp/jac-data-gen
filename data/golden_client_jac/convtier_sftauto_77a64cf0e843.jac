def decimal_to_binary(decimal: Any) -> object {
    if (decimal == 0) {
        return '0';
    }
    def divide_by_2(decimal: Any) -> object {
        if (decimal == 0) {
            return '';
        } elif ((decimal % 2) == 0) {
            return (divide_by_2((decimal // 2)) + '0');
        } else {
            return (divide_by_2((decimal // 2)) + '1');
        }
    }
    binary = divide_by_2(decimal);
    return binary;
}



with entry {
    print(decimal_to_binary(5));
    print(decimal_to_binary(10));
    print(decimal_to_binary(2));
}
