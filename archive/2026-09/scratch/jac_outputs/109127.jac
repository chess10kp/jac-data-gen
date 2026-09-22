"""Return the maximal suffix of p which is also a prefix of w."""
def sufpre(p: str, w: str) -> str {
    for i in range(len(p)) {
        if w.startswith(p[i:]) {
            return p[i:];
        }
    }
    return '';
}