"""
    Adds leading and trailing zeros to value ("pads" the value).

    >>> pad(5)
    05
    >>> pad(9, 3)
    009

    :param int value: integer value to pad
    :param int length: Length to pad to
    :return: string of padded value
    :rtype: str
    """
def pad(value: Any, length: Any = 2) -> object {
    return "{0:0>{width}}".format(value, width=length);
}