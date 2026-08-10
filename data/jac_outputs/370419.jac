"""
    Returns a single character '0' or '1'
    representing the logical OR of bit a and bit b (which are each '0' or '1')

    >>> OR('0', '0')
    '0'
    >>> OR('0', '1')
    '1'
    >>> OR('1', '0')
    '1'
    >>> OR('1', '1')
    '1'

    """
def OR(a: Any, b: Any) -> object {
    if ((a == '0') and (b == '0')) {
        return '0';
    }
    return '1';
}