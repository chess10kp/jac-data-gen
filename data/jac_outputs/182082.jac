"""Estimate the edit distance between predicted and ref phone sequences."""
def phone_edit_distance(predicted_str: str, ref_str: str) -> int {
    predicted_list = predicted_str.split(" ");
    ref_list = ref_str.split(" ");
    (m, n) = (len(predicted_list), len(ref_list));
    dp = [[0] * (m + 1) for _ in range(n + 1)];
    dp[0][0] = 0;
    for i in range(1, m + 1) {
        dp[0][i] = i;
    }
    for i in range(1, n + 1) {
        dp[i][0] = i;
    }
    for i in range(1, m + 1) {
        for j in range(1, n + 1) {
            if predicted_list[i - 1] == ref_list[j - 1] {
                dp[j][i] = dp[j - 1][i - 1];
            } else {
                dp[j][i] = min(dp[j - 1][i] + 1, dp[j][i - 1] + 1, dp[j - 1][i - 1] + 1);
            }
        }
    }
    return dp[n][m];
}