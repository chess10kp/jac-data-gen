"""Return the length of the longest common subsequence of two token lists."""
def my_lcs(string: list[str], sub: list[str]) -> int {
    if len(string) < len(sub) {
        (sub, string) = (string, sub);
    }
    lengths = [
        [0 for _ in range(len(sub) + 1)] for _ in range(len(string) + 1)
    ];
    for j in range(1, len(sub) + 1) {
        for i in range(1, len(string) + 1) {
            if string[i - 1] == sub[j - 1] {
                lengths[i][j] = lengths[i - 1][j - 1] + 1;
            } else {
                lengths[i][j] = max(lengths[i - 1][j], lengths[i][j - 1]);
            }
        }
    }
    return lengths[len(string)][len(sub)];
}