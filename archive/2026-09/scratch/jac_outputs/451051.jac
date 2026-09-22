"""Converts incoming value to a unicode string."""
def safe_stringify(value: str | bytes | int | float | bool) -> str {
    if isinstance(value, str) {
        return value;
    }
    if isinstance(value, bytes) {
        return value.decode("utf-8");
    }
    return str(value);
}