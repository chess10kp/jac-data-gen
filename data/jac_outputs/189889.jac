"""
    Get the first value in the list of values as a string.
    """
def first(values: Any) -> object {
    if isinstance(values, (str, bytes)) {
        return values;
    }
    value = values[0];
    if isinstance(value, str) {
        return values[0];
    }
    return str(value);
}