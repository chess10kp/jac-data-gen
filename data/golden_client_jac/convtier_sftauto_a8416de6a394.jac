def increment_by_1(n: Any) -> object {
    mask = 1;
    while (n & mask) {
        n ^= mask;
        mask <<= 1;
    }
    n ^= mask;
    return n;
}



with entry {
    print(increment_by_1(5));
    print(increment_by_1(10));
    print(increment_by_1(2));
}
