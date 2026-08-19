def fib(n: int) -> int {
    if n <= 1 {
        return n;
    }
    prev = 0;
    curr = 1;
    for _ in range(2, n + 1) {
        next_val = prev + curr;
        prev = curr;
        curr = next_val;
    }
    return curr;
}

with entry {
    for i in range(10) {
        print(f"fib({i}) = {fib(i)}");
    }
}
