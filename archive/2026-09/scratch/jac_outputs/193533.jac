"""
    Return the standard length string of css.
    It's compatible with number values in old versions.
    :param l: source css length.
    :return: A string.
    """
def to_css_length(l: Any) -> object {
    if isinstance(l, (int, float)) {
        return '{}px'.format(l);
    } else {
        return l;
    }
}