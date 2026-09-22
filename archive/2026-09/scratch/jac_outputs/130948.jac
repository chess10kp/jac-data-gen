"""Return list of characters from a byte string (PY3-compatible).

    In PY2, list(byte_string)` works fine, but in PY3, this returns
    each element as an int instead of single character byte string.
    Slicing is used instead to get the individual characters.

    Parameters
    ----------
    byte_string : bytes
        Byte string to be split into characters.

    Returns
    -------
    chars : list
        The individual characters, each as a byte string.
    """
def byte_chars(byte_string: bytes) -> list[bytes] {
    [byte_string[i:(i + 1)] for i in range(len(byte_string))]
}