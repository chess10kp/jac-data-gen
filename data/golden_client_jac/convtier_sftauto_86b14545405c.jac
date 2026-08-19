def fibonacci(n: Any) -> object {
    (a, b, c) = (0, 1, 0);
    if (n <= 0) {
        return 0;
    } elif (n == 1) {
        return 1;
    } else {
        for _ in range(2, (n + 1)) {
            c = a + b;
            a = b;
            b = c;
        }
        return c;
    }
}



with entry {
    print(fibonacci(5));
    print(fibonacci(10));
    print(fibonacci(2));
}
