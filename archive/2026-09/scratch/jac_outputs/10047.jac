"""Suffix strip

    >>> sstrip('foo.oof', '.oof')
    'foo'
    >>> sstrip('baroof', '.oof')
    'baroof'
    """
def sstrip(s: Any, suffix: Any) -> object {
    i = -len(suffix);
    if (s[i:] == suffix) {
        return s[:i];
    }
    return s;
}