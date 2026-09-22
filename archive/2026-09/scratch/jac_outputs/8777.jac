"""Sum even Fib numbers below 'limit'."""
def evenFibSum(limit: int) -> int {
    sum = 0;
    (a, b) = (1, 2);
    while b < limit {
        if b % 2 == 0 {
            sum += b;
        }
        (a, b) = (b, a + b);
    }
    return sum;
}