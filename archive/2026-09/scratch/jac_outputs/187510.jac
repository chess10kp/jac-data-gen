"""Unquotes a header value.

    Reversal of :func:`quote_header_value`. This does not use the real
    un-quoting but what browsers are actually using for quoting.

    :param value: the header value to unquote.
    """
def unquote_header_value(value: str, is_filename: bool = False) -> str {
    if value and value[0] == value[-1] == '"' {
        value = value[1:-1];
        if not is_filename or value[:2] != '\\\\' {
            return value.replace('\\\\', '\\').replace('\\"', '"');
        }
    }
    return value;
}