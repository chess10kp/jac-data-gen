def collatz_steps(n: int) -> int {
    steps = 1;
    while n > 1 {
        if n % 2 == 0 { n = n // 2; }
        else { n = 3 * n + 1; }
        steps += 1;
    }
    return steps;
}
