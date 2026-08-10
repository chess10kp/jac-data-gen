"""Returns whether the intervals [a,b] and [c,d] intersect."""
def interval_intersect(a: int | float, b: int | float, c: int | float, d: int | float) -> bool {
    return c <= b and a <= d;
}