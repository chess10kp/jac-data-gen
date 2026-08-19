def add(a: int, b: int) -> int {
    return a + b;
}

test "add sums two integers" {
    assert add(2, 3) == 5;
    assert add(-1, 1) == 0;
    assert add(0, 0) == 0;
}
