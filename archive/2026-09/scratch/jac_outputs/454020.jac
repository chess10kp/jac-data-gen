"""
    Return true if s can be converted into a valid integer, and false otherwise.

    :param s: value to check if can be converted into a valid integer
    :return: true if s can be converted into a valid integer, false otherwise
    >>> is_valid_int("hello")
    False
    >>> is_valid_int("506")
    True
    """
def is_valid_int(s: str) -> bool {
    try {
        int(s);
    } except ValueError {
        return False;
    } else {
        return True;
    }
}