"""Measure edit distance between two strings."""
def levenshtein(string1: str, string2: str) -> int {
    (n, m) = (len(string1), len(string2));
    if n > m {
        (string1, string2, n, m) = (string2, string1, m, n);
    }
    current = list(range(n + 1));
    for i in range(1, m + 1) {
        (previous, current) = (current, [i] + [0] * n);
        for j in range(1, n + 1) {
            (insert, delete, replace) = (
                previous[j] + 1,
                current[j - 1] + 1,
                previous[j - 1]
            );
            if string1[j - 1] != string2[i - 1] {
                replace += 1;
            }
            current[j] = min(insert, delete, replace);
        }
    }
    return current[n];
}