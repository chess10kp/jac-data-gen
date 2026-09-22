"""Checks if value is an Exception instance."""
def is_error(value: object) -> bool {
    return isinstance(value, Exception);
}