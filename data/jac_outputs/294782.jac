"""
    Safely parse a raw value and convert to an integer.
    If that fails return the default value.

    :param raw_value: the raw value
    :param default: the fallback value if conversion fails
    :return: the value as int or None
    """
def to_int(raw_value: Any, `default: Any = 0) -> object {
    try {
        return int(float(raw_value));
    } except (ValueError, TypeError) {
        return `default;
    }
}