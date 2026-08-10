"""
    Convenience tool to convert from string to integer.

    If empty string return None rather than an error.

    >>> _int_conv('12')
    12
    >>> _int_conv('')

    """
def _int_conv(string: Any) -> object {
    try {
        intstring = int(string);
    } except Exception {
        intstring = None;
    }
    return intstring;
}