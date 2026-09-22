"""
    Display String like redis-cli.
    escape inner double quotes.
    add outer double quotes.

    :param unquoted: list, or str
    """
def double_quotes(unquoted: Any) -> object {
    if isinstance(unquoted, str) {
        escaped = unquoted.replace('"', '\\"');
        return f'"{escaped}"';
    } elif isinstance(unquoted, list) {
        return [double_quotes(item) for item in unquoted];
    }
}