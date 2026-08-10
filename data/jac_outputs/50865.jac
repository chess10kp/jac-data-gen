"""
    Check to see if a string has the same amount of 'x's and 'o's. The method must return a boolean and be
    case insensitive. The string can contain any char.
    :param s: A string value input.
    :return: True if amount of 'x's and 'o's are the same, Else False.
    """
def xo(s: Any) -> object {
    return (s.lower().count("x") == s.lower().count("o"));
}