"""
    Perform recursive fast exponentiation by squaring.

    :param x: the base number
    :param n: the target power value, an integer
    :return: x to the power of n
    """
def fpow0(x: Any, n: Any) -> object {
    if (n < 0) {
        return fpow0((1 / x), -n);
    }
    if (n == 0) {
        return 1;
    }
    if (x == 0) {
        return 0;
    }
    assert (n == int(n)) , "n must be an integer";
    return fpow0((x * x), (n // 2))
        if ((n % 2) == 0)
        else (x * fpow0((x * x), (n // 2)));
}