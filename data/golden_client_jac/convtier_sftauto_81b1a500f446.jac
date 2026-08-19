def fibonacci(n: Any) -> object {
    if (n < 0) {
        return "Invalid input: n must be a non-negative integer.";
    }
    if (n == 0) {
        return 0;
    }
    if (n == 1) {
        return 1;
    }
    a = 0;
    b = 1;
    for _ in range(2, (`abs(n) + 1)) {
        (a, b) = (b, (a + b));
    }
    return b if (n > 0) else -b;
}



with entry {
    print(fibonacci(5));
    print(fibonacci(10));
    print(fibonacci(2));
}
