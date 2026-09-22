"""
Naive method for string searching.
Returns list of start indexes where word w occurs in text t.
"""
def naive(t: str, w: str) -> list[int] {
    n = len(t);
    m = len(w);
    indexes = [];
    d = 0;
    i = 0;
    while d < n - m {
        if i == m {
            indexes.append(d);
            i = 0;
            d += 1;
        }
        if t[d + i] == w[i] {
            i += 1;
        } else {
            i = 0;
            d += 1;
        }
    }
    return indexes;
}