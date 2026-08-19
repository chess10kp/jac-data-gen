def fibonacci(n: Any) -> object {
    if (n <= 0) {
        return None;
    }
    if (n == 1) {
        return 0;
    }
    if (n == 2) {
        return 1;
    }
    (fib1, fib2) = (0, 1);
    for _ in range(3, (n + 1)) {
        fib = fib1 + fib2;
        (fib1, fib2) = (fib2, fib);
    }
    return fib2;
}



with entry {
    print(fibonacci(5));
    print(fibonacci(10));
    print(fibonacci(2));
}
