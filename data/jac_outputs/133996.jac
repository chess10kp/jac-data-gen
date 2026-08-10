""" matches if the current position is not followed by the pattern

    :param pattern: an `re` pattern
    :type pattern: str

    :rtype: str
    """
def not_followed_by(pattern: Any) -> object {
    return r'(?!{:s})'.format(pattern);
}