"""Return a formatted strings

    :param data: a list of strings
    :param separator: the separator to use between strings (default: ', ')
    :rtype: a string formatted based on separator
    """
def format_list(data: Any, separator: Any = ', ') -> object {
    if (data is None) {
        return None;
    }
    return separator.join(sorted(data));
}