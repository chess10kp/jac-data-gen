def abs_val(n: int) -> int {
    if n < 0 {
        return -n;
    }
    return n;
}

with entry {
    for x in [5, -5, 0, -123, 42] {
        print(abs_val(x));
    }
}
