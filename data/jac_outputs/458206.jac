"""
    Replace all recursive tail calls f(x=x1, y=y1, ...) with (x, y, ...) = (x1, y1, ...); continue
    """
def factorial_3(n: Any, acc: Any = 1) -> object {
    while True {
        if (n < 2) {
            return (1 * acc);
        }
        (n, acc) = ((n - 1), (acc * n));
        continue;
        break;
    }
}