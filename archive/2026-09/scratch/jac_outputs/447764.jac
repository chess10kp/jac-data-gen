"""Converts input to unicode if necessary.
    If `s` is bytes, it will be decoded using the `encoding` parameters.
    This function is used for preprocessing /source/ and /filename/ arguments
    to the builtin function `compile`.
    """
def ensureUtf(s: Any, encoding: Any = 'utf8') -> object {
    if (`type(s) == `bytes) {
        return s.decode(encoding, 'ignore');
    } else {
        return s;
    }
}