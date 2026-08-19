def fib(n: int) -> int {
    if n < 2 { return n; }
    a = 0; b = 1;
    for _ in range(2, n + 1) { (a, b) = (b, a + b); }
    return b;
}

with entry {
    print(fib(10));
}
