"""
    Returns minimum number of blocks with length ``block``
    necessary to cover the array with length ``length``.
    """
def min_blocks(length: Any, block: Any) -> object {
    return (((length - 1) // block) + 1);
}