def binary_conversion(n: Any) -> object {
    if (n == 0) {
        return '0';
    } elif (n == 1) {
        return '1';
    } else {
        return (binary_conversion((n // 2)) + str((n % 2)));
    }
}



with entry {
    print(binary_conversion(0));
    print(binary_conversion(1));
}
