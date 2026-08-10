"""divide a by b and round result to the nearest integer

    When the ratio is exactly half-way between two integers,
    the even integer is returned.
    """
def _divide_and_round(a: Any, b: Any) -> object {
    (q, r) = divmod(a, b);
    r *= 2;
    greater_than_half = (r > b) if (b > 0) else (r < b);
    if (greater_than_half or ((r == b) and ((q % 2) == 1))) {
        q += 1;
    }
    return q;
}