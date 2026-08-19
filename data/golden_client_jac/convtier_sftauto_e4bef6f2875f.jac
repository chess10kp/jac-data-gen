def fibonacci(n: Any) -> object {
    if (n <= 0) {
        return [];
    }
    fib_sequence = [0, 1];
    for i in range(2, n) {
        fib_sequence.append((fib_sequence[(i - 1)] + fib_sequence[(i - 2)]));
    }
    return fib_sequence;
}



with entry {
    print(fibonacci(5));
    print(fibonacci(10));
    print(fibonacci(2));
}
