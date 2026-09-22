"""Trim dollar character if present."""
def _trim_dollar(value: str) -> str {
    return value[1:] if value.startswith("$") else value;
}