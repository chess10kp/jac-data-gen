"""Converts input value to string."""
def _convert_to_string(input_value: str | int | float | bool | list[str] | dict[str, str] | None) -> str {
    try {
        return str(input_value).strip().upper();
    } except Exception {
        return '';
    }
}