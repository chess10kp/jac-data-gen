def fibonacci(limit: int) -> int {
    a = 0;
    b = 1;
    while a < limit {
        yield a;
        (a, b) = (b, a + b);
    }
}
