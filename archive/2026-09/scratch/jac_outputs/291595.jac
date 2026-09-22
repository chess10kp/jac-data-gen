"""Return True if ``d[k,j] = 0`` for ``0 <= k < i``

    Here ``d`` is a bit matrix implemented as an array of integers.
    """
def zero_column(d: list[int], j: int, i: int) -> bool {
    s = 0;
    for k in range(i) {
        s |= d[k];
    }
    return (s & (1 << j)) == 0;
}