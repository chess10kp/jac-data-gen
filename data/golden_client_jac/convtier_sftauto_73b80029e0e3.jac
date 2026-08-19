def fibonacci(n: Any) -> object {
    if (n <= 0) {
        return [];
    }
    fib_seq = [0] * n;
    fib_seq[0] = 0;
    if (n > 1) {
        fib_seq[1] = 1;
    }
    for i in range(2, n) {
        fib_seq[i] = fib_seq[(i - 1)] + fib_seq[(i - 2)];
    }
    return fib_seq;
}



with entry {
    print(fibonacci(5));
    print(fibonacci(10));
    print(fibonacci(2));
}
