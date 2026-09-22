"""
    Create a bitmask of `n` ones.
    """
def bitmask(n: Any) -> object {
    return ((1 << n) - 1);
}