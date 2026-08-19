def digit_sum(n: int) -> int {
    n = abs(n);
    total = 0;
    while n > 0 {
        total += n % 10;
        n = n // 10;
    }
    return total;
}

with entry {
    for x in [0, 5, 42, 12345, 99999] {
        print(digit_sum(x));
    }
}
