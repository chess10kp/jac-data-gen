"""
    Input:
        vector: a list or (1d) numpy array
    Returns:
        a dict with {idx:value} for all values of the vector
    """
def vec2dict(vector: list[int]) -> dict[int, int] {
    {i: val for (i, val) in enumerate(vector)}
}