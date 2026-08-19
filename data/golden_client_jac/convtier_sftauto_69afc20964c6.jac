def fibonacci_sequence(n: Any) -> object {
    if (n <= 0) {
        return [];
    }
    fib_seq = [0, 1];
    if (n <= 1) {
        return fib_seq[:(n + 1)];
    }
    while (len(fib_seq) <= n) {
        fib_seq.append((fib_seq[-1] + fib_seq[-2]));
    }
    return fib_seq;
}



with entry {
    print(fibonacci_sequence(5));
    print(fibonacci_sequence(10));
    print(fibonacci_sequence(2));
}
