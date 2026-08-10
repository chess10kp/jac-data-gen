"""Is node n a left descendant of the root in a zero-indexed boolean tree?"""
def left(n: int) -> bool {
    while n > 2 {
        n = (n - 1) // 2;
    }
    return n == 1;
}