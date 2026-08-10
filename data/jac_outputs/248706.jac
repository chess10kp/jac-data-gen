"""Return the multiple of `n` the closest to the integer `x`."""
def int_round(x: int, n: int) -> int {
    return (n * round((x / n)));
}