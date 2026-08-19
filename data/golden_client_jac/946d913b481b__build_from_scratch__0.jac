def clamp(x: int, lo: int, hi: int) -> int {
    if x < lo {
        return lo;
    }
    if x > hi {
        return hi;
    }
    return x;
}

with entry {
    print(clamp(5, 0, 10));
    print(clamp(-3, 0, 10));
    print(clamp(15, 0, 10));
    print(clamp(0, 0, 10));
    print(clamp(10, 0, 10));
}
