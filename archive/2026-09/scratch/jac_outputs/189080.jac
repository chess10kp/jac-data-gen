"""
    Convert a binary string to hexadecimal.

    If any non 0/1 values are present such as 'x', return that single character
    as a representation.

    :param s: the string to be converted
    :type s: str
    """
def binary_string_to_hex(s: Any) -> object {
    for c in s {
        if not (c in '01') {
            return c;
        }
    }
    return hex(int(s, 2))[2:];
}