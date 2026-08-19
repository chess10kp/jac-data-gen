def add(a: int, b: int) -> int {
    return a + b;
}

test "add returns the sum of its two arguments" {
    assert add(2, 3) == 5;
    assert add(-1, 1) == 0;
}
