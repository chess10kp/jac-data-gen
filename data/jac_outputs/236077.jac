"""
    Providing n'th hexagonal number.

    :param nth: index for n'th hexagonal
    :returns: n'th hexagonal number
    see http://en.wikipedia.org/wiki/Hexagonal_number

    >>> hexagonal(3)
    15
    >>> hexagonal(4)
    28
    """
def hexagonal(nth: int) -> int {
    return nth * (2 * nth - 1);
}