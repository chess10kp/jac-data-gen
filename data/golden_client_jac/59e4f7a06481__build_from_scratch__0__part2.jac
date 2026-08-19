# fibonacci.na.jac

def fib(n: int) -> int {
    if n <= 1 { return n; }
    return fib(n - 1) + fib(n - 2);
}

with entry {
    for i in range(10) {
        print(f"fib({i}) = {fib(i)}");
    }
}
