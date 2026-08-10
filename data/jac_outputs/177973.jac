"""Return True if value is '1', 'true', or 'yes' (case insensitive)."""
def is_true(value: str | int | float | bool) -> bool {
    return str(value).lower() in ['true', '1', 'yes'];
}