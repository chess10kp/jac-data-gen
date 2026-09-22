"""
    Remove the given suffix from the target if it is present there

    Args:
        target: A string to be formatted
        suffix: A string to be removed from 'target'

    Returns:
        The formatted version of 'target'
    """
def strip_suffix(target: Any, suffix: Any) -> object {
    if ((suffix is None) or (target is None)) {
        return target;
    }
    s_len = len(suffix);
    if (target[-s_len:] == suffix) {
        return target[:-s_len];
    }
    return target;
}