"""Find a substring by Knuth-Morris-Pratt; returns start index or -1."""
def knuth_morris_pratt(s: str, t: str) -> int {
    assert t != '';
    len_s = len(s);
    len_t = len(t);
    r = [0] * len_t;
    j = r[0] = -1;
    for i in range(1, len_t) {
        while j >= 0 and t[i - 1] != t[j] {
            j = r[j];
        }
        j += 1;
        r[i] = j;
    }
    j = 0;
    for i in range(len_s) {
        while j >= 0 and s[i] != t[j] {
            j = r[j];
        }
        j += 1;
        if j == len_t {
            return i - len_t + 1;
        }
    }
    return -1;
}