"""Kronecker delta function."""
def kdelta(i: int, j: int) -> int {
    assert i in (0, 1);
    assert j in (0, 1);
    return i * j;
}