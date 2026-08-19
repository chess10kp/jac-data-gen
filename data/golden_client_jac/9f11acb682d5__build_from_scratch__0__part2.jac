def sign(n: int) -> int {
    if n > 0 {
        return 1;
    }
    if n < 0 {
        return -1;
    }
    return 0;
}

with entry {
    for x in [7, -4, 0, 100, -1] {
        print(sign(x));
    }
}
