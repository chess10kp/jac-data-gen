def is_perfect(n: int) -> bool {
    total = 0;
    for i in range(1, n) {
        if n % i == 0 { total += i; }
    }
    return total == n;
}

with entry {
    print(is_perfect(6));
}
