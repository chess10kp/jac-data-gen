"""Find the position of the first character that doesn't match."""
def first_diff_pos(a: str, b: str) -> int {
    for (i, c) in enumerate(a) {
        if i >= len(b) {
            return i;
        }
        if b[i] != a[i] {
            return i;
        }
    }
    return len(a);
}