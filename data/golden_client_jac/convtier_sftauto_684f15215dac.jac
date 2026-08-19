def fibonacci(n: Any) -> object {
    if (n <= 1) {
        return n;
    }
    (a, b) = (0, 1);
    i = 2;
    while (i <= n) {
        (a, b) = (b, (a + b));
        i += 1;
    }
    return b;
}



with entry {
    print(fibonacci(5));
    print(fibonacci(10));
    print(fibonacci(2));
}
