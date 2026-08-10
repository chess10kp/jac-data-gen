"""
    Returns the smallest power of two which is >= x.
    """
def next_power_of_2(x: int) -> object {
    assert (isinstance(x, int) and (x > 0));
    res = 2 ** (x - 1).bit_length();
    assert (x <= res < (2 * x)) , f'{x}, {res}';
    return res;
}