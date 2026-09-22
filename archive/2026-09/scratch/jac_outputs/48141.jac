"""
    What is the minimum number of trials we need to drop eggs to determine which floors of a building are safe for
    dropping eggs, given n eggs and k floors?
    :param n: number of eggs
    :param k: number of floors
    :return: the minimum number of trials

    >>> egg_drop(1, 5)
    5
    >>> egg_drop(2,36)
    8
    """
def egg_drop(n: int, k: int) -> int {
    if n == 1 {
        return k;
    }
    if k == 1 or k == 0 {
        return k;
    }
    return 1 + min([
        max(egg_drop(n - 1, x - 1), egg_drop(n, k - x))
        for x in range(1, k + 1)
    ]);
}