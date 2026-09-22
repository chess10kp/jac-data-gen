"""
    Rotate (shift) the list, moving values n places to the left/right
    """
def rotate(l: list[int], n: int) -> list[int] {
    n = -n;
    return l[n:] + l[:n];
}