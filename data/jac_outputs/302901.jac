"""[summary]
    This algorithm computes the n-th fibbonacci number
    very quick. approximate O(n)
    The algorithm use dynamic programming.

    Arguments:
        n {[int]} -- [description]

    Returns:
        [int] -- [description]
    """
def fib_list(n: Any) -> object {
    assert (n >= 0) , 'n must be a positive integer';
    list_results = [0, 1];
    for i in range(2, (n + 1)) {
        list_results.append((list_results[(i - 1)] + list_results[(i - 2)]));
    }
    return list_results[n];
}