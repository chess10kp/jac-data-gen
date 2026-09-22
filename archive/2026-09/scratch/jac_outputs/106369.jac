"""Dump a dict object into a string representation of key-value pairs."""
def key_value_string(`obj: dict[str, str | int | float | bool]) -> str {
    return ", ".join(f"{k}={v}" for (k, v) in sorted(`obj.items()));
}