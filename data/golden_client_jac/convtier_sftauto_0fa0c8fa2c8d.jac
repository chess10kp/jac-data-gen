def fibonacci(n: Any) -> object {
    fib = [0, 1];
    for i in range(2, (n + 1)) {
        fib.append(((fib[(i - 1)] + fib[(i - 2)]) % 1000000007));
    }
    return fib[n];
}



with entry {
    print(fibonacci(5));
    print(fibonacci(10));
    print(fibonacci(2));
}
