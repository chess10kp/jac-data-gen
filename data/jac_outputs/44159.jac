"""Compare the two options and choose best permutation."""
def isGreaterOrEqual(a: int | str, b: int | str) -> int | str {
    ab = str(a) + str(b);
    ba = str(b) + str(a);
    return a if ab > ba else b;
}