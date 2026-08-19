def computeFibonacci(n: Any) -> object {
    fib = [0, 1];
    (a, b) = (0, 1);
    i = 2;
    while True {
        fib.append((a + b));
        (a, b) = (b, fib[i]);
        if (fib[i] > n) {
            break;
        }
        i += 1;
    }
    return fib;
}



with entry {
    print(computeFibonacci(5));
    print(computeFibonacci(10));
    print(computeFibonacci(2));
}
