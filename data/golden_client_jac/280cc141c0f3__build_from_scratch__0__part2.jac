def collatz_steps(n: int) -> int {
    steps = 0;
    while n > 1 {
        if n % 2 == 0 {
            n = n // 2;
        } else {
            n = 3 * n + 1;
        }
        steps += 1;
    }
    return steps;
}

with entry {
    for x in [1, 2, 6, 7, 27] {
        print(collatz_steps(x));
    }
}
