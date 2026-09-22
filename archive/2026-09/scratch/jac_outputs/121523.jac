"""
    >>> join_if_not_empty('SEP', '', '')
    ''
    >>> join_if_not_empty('SEP', 'a', '')
    'a'
    >>> join_if_not_empty('SEP', 'a', ' ')
    'aSEP '
    >>> join_if_not_empty('SEP', 'a', 'b')
    'aSEPb'
    """
def join_if_not_empty(sep: str, str1: str, str2: str) -> str {
    if ((str1 != '') and (str2 != '')) {
        result = sep.join((str1, str2));
    } else {
        result = max(str1, str2);
    }
    return result;
}