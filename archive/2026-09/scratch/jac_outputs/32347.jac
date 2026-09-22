"""Multiply factor by constant with type checks."""
def multiply_1(factor: int) -> int {
    print(type(factor));
    factor_var = int(factor);
    assert type(factor_var) == int;
    return int(factor_var * 23.233223);
}