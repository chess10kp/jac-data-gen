"""Finds longest common subsequence."""
def lcs(x: str, y: str) -> int {
    m = len(x);
    n = len(y);
    c = [[0] * (n + 1) for _ in range(m + 1)];
    for i in range(1, m + 1) {
        for j in range(1, n + 1) {
            if x[i - 1] == y[j - 1] {
                c[i][j] = c[i - 1][j - 1] + 1;
            } else {
                c[i][j] = max(c[i][j - 1], c[i - 1][j]);
            }
        }
    }
    def back_track(i: int, j: int) -> str {
        if i == 0 or j == 0 {
            return "";
        } elif x[i - 1] == y[j - 1] {
            return back_track(i - 1, j - 1) + x[i - 1];
        } elif c[i][j - 1] > c[i - 1][j] {
            return back_track(i, j - 1);
        } else {
            return back_track(i - 1, j);
        }
    }
    return len(back_track(m, n));
}