"""Converts a 1-char byte string to int.

This function is used for python2 and python3 compatibility
that can also handle an integer input.

Args:
    i: The 1-char byte string to convert to an int.

Returns:
    The byte string value as int or i if the input was already an
    integer.
"""
def _ord(i: int | bytes | str) -> int {
    if isinstance(i, int) {
        return i;
    }
    return ord(i);
}