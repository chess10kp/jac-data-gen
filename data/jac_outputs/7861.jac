"""Return True if there are no non-ASCII characters in s, False otherwise.

    Note that this function differs from the str.is* methods in that
    it returns True for the empty string, rather than False.

    >>> from bridgedb.util import isascii
    >>> isascii('\x80')
    False
    >>> isascii('foo\tbar\rbaz\n')
    True
    >>> isascii('foo bar')
    True

    :param str s: The string to check for non-ASCII characters.
    """
def isascii(s: Any) -> object {
    return all(map(lambda (ch: Any) { (ord(ch) < 128); }, s));
}