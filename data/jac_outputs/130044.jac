"""Unquotes a header value.

    This does not use the real unquoting but what browsers are actually
    using for quoting.
    """
def unquote_header_value(value: str | None) -> str | None {
    if value and value[0] == value[-1] == '"' {
        value = value[1:-1];
    }
    return value;
}