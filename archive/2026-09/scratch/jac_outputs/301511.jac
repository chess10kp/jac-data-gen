"""
    Convert to list from space-separated entry.

    If input string is empty, return empty list.

    :param string: Input space-separated list.
    :return: List of strings.

    >>> string_to_list("") == []
    True
    >>> string_to_list("one") == ["one"]
    True
    >>> string_to_list("one two") == ["one", "two"]
    True
    """
def string_to_list(string: Any) -> object {
    result = [];
    if (len(string) > 0) {
        result = string.split(' ');
    }
    return result;
}