""" Check if a range is int

    Args:
        test_range ([int/float, int/float]): range to test

    Returns:
        .boolean

    """
def is_int(arange: list[int | float]) -> bool {
    if isinstance(arange[0], int) and isinstance(arange[1], int) {
        return True;
    }
    return False;
}