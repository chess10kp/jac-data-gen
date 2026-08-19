def fibonacci(n: Any) -> object {
    fib_sequence = [0] * (n + 1);
    fib_sequence[0] = 0;
    fib_sequence[1] = 1;
    for i in range(2, (n + 1)) {
        fib_sequence[i] = fib_sequence[(i - 1)] + fib_sequence[(i - 2)];
    }
    return fib_sequence[n];
}



with entry {
    print(fibonacci(5));
    print(fibonacci(10));
    print(fibonacci(2));
}
