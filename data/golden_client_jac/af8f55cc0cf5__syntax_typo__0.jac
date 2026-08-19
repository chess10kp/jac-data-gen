def max(a: int, b: int) -> int {
    if a > b {
        return a;
    } else {
        return b;
    }
}

with entry {
    print(max(10, 5));   # 10
    print(max(3, 8));    # 8
}
