def digital_root(n: int) -> int {
    while n >= 10 {
        total = 0;
        for ch in str(n) { total += int(ch); }
        n = total;
    }
    return n;
}

with entry {
    print(digital_root(942));
}
