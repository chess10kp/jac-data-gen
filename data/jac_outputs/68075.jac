"""Ensure that the arguments of a function cannot go out of bounds."""
def fieldargs(field: int, width: int) -> tuple[int, int] {
    w = width or 1;
    assert field >= 0, 'Field cannot be negative.';
    assert w > 0, 'Width must be positive.';
    assert field + w <= 32, 'Bits accessed excede 32.';
    return (field, w);
}