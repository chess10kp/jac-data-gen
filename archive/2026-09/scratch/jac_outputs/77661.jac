def fibonacci_loop(n: int) -> int {
    if n == 0 {
        return 0;
    }
    cache = [0, 1];
    for _ in range(n - 2) {
        (cache[0], cache[1]) = (cache[1], cache[0] + cache[1]);
    }
    return cache[0] + cache[1];
}