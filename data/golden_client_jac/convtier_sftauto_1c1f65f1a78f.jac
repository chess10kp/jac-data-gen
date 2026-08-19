def fibonacci(n: Any) -> object {
    if (n <= 0) {
        return [];
    }
    fib_list = [0, 1];
    if (n <= 1) {
        return fib_list[:(n + 1)];
    }
    for i in range(2, (n + 1)) {
        fib_list.append((fib_list[(i - 1)] + fib_list[(i - 2)]));
    }
    return fib_list;
}



with entry {
    print(fibonacci(5));
    print(fibonacci(10));
    print(fibonacci(2));
}
