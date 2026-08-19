def digit_sum(n: int) -> int {
    total = 0;
    for ch in str(n) { total += int(ch); }
    return total;
}

with entry {
    print(digit_sum(12345));
}
