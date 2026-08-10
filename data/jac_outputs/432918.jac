"""
    Follows the standard DP approach of finding common subsequence.
    The common length can be >=1 so if we find a common character in both
    the strings, it does the job
    """
def sol(a: str, b: str) -> int {
    m = len(a);
    n = len(b);
    dp = [[0 for _ in range(n + 1)] for _ in range(m + 1)];
    for i in range(1, m + 1) {
        for j in range(1, n + 1) {
            if a[i - 1] == b[j - 1] {
                dp[i][j] = 1 + dp[i - 1][j - 1];
            } else {
                dp[i][j] = max(dp[i - 1][j], dp[i][j - 1]);
            }
            if dp[i][j] >= 1 {
                return 1;
            }
        }
    }
    return 0;
}