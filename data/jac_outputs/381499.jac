"""
    Implements signed right-shift.
    See: http://stackoverflow.com/a/5833119/15677
    """
def rshift(val: Any, n: Any) -> object {
    return ((val % 4294967296) >> n);
}