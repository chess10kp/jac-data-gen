def euclids_formula(m: int, n: int) -> tuple[int, int, int] {
    assert type(m) is int, "";
    assert type(n) is int, "";
    a = m * m - n * n;
    b = 2 * m * n;
    c = m * m + n * n;
    return (min(a, b), max(a, b), c);
}