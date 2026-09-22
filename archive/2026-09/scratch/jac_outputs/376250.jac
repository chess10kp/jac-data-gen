"""Return the 1-order difference of input array."""
def diff1(array: list[int]) -> list[int] {
    return [j - i for (i, j) in zip(array[:-1], array[1:])];
}