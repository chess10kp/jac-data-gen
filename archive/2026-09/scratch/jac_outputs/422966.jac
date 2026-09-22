"""
    :param x: some number (float or int)
    :return: nearst odd integer
    """
def round_to_odd(x: Any) -> object {
    return int(((round(((x - 1) / 2)) * 2) + 1));
}