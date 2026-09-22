"""
    If _source if None, return an empty string, otherwise return string.
    This is useful when you build strings and want it to be empty if you don't have any data.
    """
def empty_if_none(_string: str | int | float | bool, _source: str | int | float | bool | list | dict | None = None) -> str {
    if _source is None {
        return "";
    }
    return str(_string);
}