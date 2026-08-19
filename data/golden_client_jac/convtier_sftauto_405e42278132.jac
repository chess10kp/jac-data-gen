def fibonacci(n: Any) -> object {
    memo = {};
    def fib(n: Any) -> object {
        if (n <= 1) {
            return n;
        }
        if (n not in memo) {
            memo[n] = fib((n - 1)) + fib((n - 2));
        }
        return memo[n];
    }
    return fib(n);
}



with entry {
    print(fibonacci(5));
    print(fibonacci(10));
    print(fibonacci(2));
}
