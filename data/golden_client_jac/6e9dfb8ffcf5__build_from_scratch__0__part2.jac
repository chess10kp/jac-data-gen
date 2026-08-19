def reverse_int(n: int) -> int {
    neg = n < 0;
    n = abs(n);
    r = 0;
    while n > 0 {
        r = r * 10 + n % 10;
        n = n // 10;
    }
    if neg {
        return -r;
    }
    return r;
}

with entry {
    for x in [123, 100, -456, 7, 0] {
        print(reverse_int(x));
    }
}
