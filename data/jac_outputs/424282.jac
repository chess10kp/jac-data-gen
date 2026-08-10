"""Convert a long to a bytestring
    For use in python version prior to 3.2
    Source:
    http://bugs.python.org/issue16580#msg177208
    """
def _long_to_bytes(n: Any, length: Any, byteorder: Any) -> object {
    if (byteorder == 'little') {
        indexes = range(length);
    } else {
        indexes = reversed(range(length));
    }
    return bytearray(((n >> (i * 8)) & 255) for i in indexes);
}