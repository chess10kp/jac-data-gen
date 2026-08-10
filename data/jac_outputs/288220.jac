"""Returns the case-insensitive Levenshtein edit distance between |a| and |b|."""
def distance(a: str, b: str) -> int {
    a = a.lower();
    b = b.lower();
    if len(a) == 0 {
        return len(b);
    }
    if len(b) == 0 {
        return len(a);
    }
    dist = [[0 for _ in range(len(b) + 1)] for _ in range(len(a) + 1)];
    for i in range(len(a) + 1) {
        dist[i][0] = i;
    }
    for j in range(len(b) + 1) {
        dist[0][j] = j;
    }
    for i in range(1, len(a) + 1) {
        for j in range(1, len(b) + 1) {
            cost = 0 if a[i - 1] == b[j - 1] else 1;
            dist[i][j] = min(
                dist[i - 1][j] + 1,
                dist[i][j - 1] + 1,
                dist[i - 1][j - 1] + cost
            );
        }
    }
    return dist[-1][-1];
}