"""
    Args:
        n: number of steps of staircase
    Returns:
        Distinct ways to climb a n step staircase
    Raises:
        AssertionError: n not positive integer
    """
def climb_stairs(n: int) -> int {
    fmt = "n needs to be positive integer, your input {}";
    assert isinstance(n, int) and n > 0, fmt.format(n);
    if n == 1 {
        return 1;
    }
    dp = [0] * (n + 1);
    (dp[0], dp[1]) = (1, 1);
    for i in range(2, n + 1) {
        dp[i] = dp[i - 1] + dp[i - 2];
    }
    return dp[n];
}