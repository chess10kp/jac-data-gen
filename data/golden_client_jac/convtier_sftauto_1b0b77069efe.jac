def decimal_to_binary(n: Any) -> object {
    binary = "";
    stack = [];
    while (n > 0) {
        stack.append((n % 2));
        n = n // 2;
    }
    while stack {
        binary += str(stack.pop());
    }
    return binary;
}



with entry {
    print(decimal_to_binary(5));
    print(decimal_to_binary(10));
    print(decimal_to_binary(2));
}
