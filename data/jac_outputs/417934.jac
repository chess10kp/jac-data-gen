"""
    Return the enclosing text or provided fallback value
    :param val: item to get text and strip whitespace
    :param fallback: fallback when val is None
    :return: stripped text value
    """
def strip_and_get(val: Any, fallback: Any = "") -> object {
    if val {
        return val.text.strip(' \t\n\r');
    } else {
        return fallback;
    }
}