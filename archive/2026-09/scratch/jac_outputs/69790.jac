"""Minimum edit distance between two strings."""
def minDistance(s1: str, s2: str) -> int {
    len1 = len(s1);
    len2 = len(s2);
    dp = [[0 for _ in range(len2 + 1)] for _ in range(len1 + 1)];
    for i in range(len1 + 1) {
        for j in range(len2 + 1) {
            if i > 0 and j == 0 {
                dp[i][j] = dp[i - 1][j] + 1;
            } elif j > 0 and i == 0 {
                dp[i][j] = dp[i][j - 1] + 1;
            } elif j > 0 and i > 0 {
                res1 = dp[i - 1][j] + 1;
                res2 = dp[i][j - 1] + 1;
                res3 = dp[i - 1][j - 1] + (0 if s1[i - 1] == s2[j - 1] else 1);
                dp[i][j] = min(res1, res2, res3);
            }
        }
    }
    return dp[len1][len2];
}