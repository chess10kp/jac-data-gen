"""Add 1 to the int in that string

    >>> increment('1') == '2'
    True
    """
def increment(string: Any) -> object {
    return str((int(string) + 1));
}