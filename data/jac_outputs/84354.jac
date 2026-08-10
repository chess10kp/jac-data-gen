"""Convert NxN or N,N to tuple."""
def pair(pairstr: str) -> tuple[int, ...] {
    return tuple(int(_s) for _s in pairstr.replace('x', ',').split(','));
}