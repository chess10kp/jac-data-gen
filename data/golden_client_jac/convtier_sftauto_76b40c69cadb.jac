def fibonacci_sum(n: Any) -> object {
    fib_sum = 0;
    fib_prev = 0;
    fib_curr = 1;
    for i in range(n) {
        fib_sum += fib_curr;
        (fib_prev, fib_curr) = (fib_curr, (fib_prev + fib_curr));
    }
    return fib_sum;
}



with entry {
    print(fibonacci_sum(5));
    print(fibonacci_sum(10));
    print(fibonacci_sum(2));
}
