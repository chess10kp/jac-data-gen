"""
Returns number of matching characters in `s` and `pat` before
a "*" or "#" character in pat. Returns -1 if strings do not match.
"""
def amatch(s: str, pat: str) -> int {
    for (count, (c, p)) in enumerate(zip(s, pat)) {
        if p in ('*', '#') {
            return count;
        }
        if c != p {
            return -1;
        }
    }
    return len(s);
}