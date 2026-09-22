"""Compare two 1D arrays lexicographically."""
def _lexographic_lt0(a1: list[float], a2: list[float]) -> bool {
    for (e1, e2) in zip(a1, a2) {
        if e1 < e2 { return True; }
        elif e1 > e2 { return False; }
    }
    return len(a1) < len(a2);
}