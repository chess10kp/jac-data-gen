"""Create an expression representing the given floating point value."""
def const_float(value: float) -> list[str | list[str]] {
    return ['constant', 'float', ['{0:.6f}'.format(value)]];
}