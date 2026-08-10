"""
    Computes Stirling number of the second kind

    Parameters
    ----------
    n: int
        Numeric. If non-integer passed in, will attempt to cast as integer

    k: int
        Numeric. If non-integer passed in, will attempt to cast as integer

    Returns
    -------
    int
        Stirling number of the second kind
    """
def stirling_second(n: int, k: int) -> object {
    try {
        (k, n) = (int(k), int(n));
    } except (ValueError, TypeError) {
        raise TypeError("`k` and `n` must both be integers");
    }
    assert (0 <= k <= n) , "`k` must be in the range of [0, `n`]";
    if ((n == 0) or (n == k)) {
        return 1;
    }
    if (k == 0) {
        return 0;
    }
    s = [1, *([0] * (k - 1))];
    for _ in range(1, n) {
        last_row = [*s];
        for i in range(1, k) {
            s[i] = ((i + 1) * last_row[i]) + last_row[(i - 1)];
        }
    }
    return s[-1];
}