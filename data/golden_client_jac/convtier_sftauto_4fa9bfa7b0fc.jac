def fibonacci(n: Any) -> object {
    fib_nums = [0, 1];
    for i in range(2, n) {
        fib_nums.append((fib_nums[(i - 1)] + fib_nums[(i - 2)]));
    }
    return fib_nums[:n];
}



with entry {
    print(fibonacci(5));
    print(fibonacci(10));
    print(fibonacci(2));
}
