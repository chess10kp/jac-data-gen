"""Return value on success, or default when an exception occurs."""
def set_field_value(
    value: str | int | float | object,
    `default: str | int | float | object | None = None
) -> str | int | float | object | None {
    try {
        return value;
    } except Exception {
        return `default;
    }
}