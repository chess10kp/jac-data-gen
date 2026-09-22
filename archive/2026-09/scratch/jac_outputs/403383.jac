"""Python 2–style three-way compare: negative, zero, or positive."""
def cmp[T](x: T, y: T) -> int {
    return (x > y) - (x < y);
}