"""Perform regular simple expression matching."""
def isMatch(s: str, p: str) -> bool {
    dp = [[False] * (len(p) + 1) for _ in range(len(s) + 1)];
    dp[0][0] = True;
    for ii in range(1, len(p)) {
        if p[ii] == "*" and dp[0][ii - 1] {
            dp[0][ii + 1] = True;
        }
    }
    for ii in range(len(s)) {
        for jj in range(len(p)) {
            if p[jj] in {s[ii], '.'} {
                dp[ii + 1][jj + 1] = dp[ii][jj];
            } elif p[jj] == '*' {
                if p[jj - 1] not in {s[ii], '.'} {
                    dp[ii + 1][jj + 1] = dp[ii + 1][jj - 1];
                } else {
                    dp[ii + 1][jj + 1] = (
                        dp[ii][jj + 1] or dp[ii + 1][jj] or dp[ii + 1][jj - 1]
                    );
                }
            }
        }
    }
    return dp[-1][-1];
}