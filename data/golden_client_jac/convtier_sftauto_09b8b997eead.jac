def decimal_to_binary(n: Any) -> object {
    if (n == 0) {
        return "0";
    } elif (n == 1) {
        return "1";
    } else {
        return (decimal_to_binary((n // 2)) + str((n % 2)));
    }
}



with entry {
    print(decimal_to_binary(0));
    print(decimal_to_binary(1));
}
