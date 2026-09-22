"""
    Returns a list of bits for a char.
    """
def bitlist(n: Any) -> object {
    return [((n >> i) & 1) for i in range(7, -1, -1)];
}