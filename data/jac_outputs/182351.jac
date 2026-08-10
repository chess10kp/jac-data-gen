"""Convert value to string if needed."""
def _to_str(value: int | str | float | bool | None) -> str {
    return '' if value is None else str(value);
}