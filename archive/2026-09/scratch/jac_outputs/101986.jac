"""Adds a space after each comma, to allow word-wrapping of
long comma-separated lists."""
def expand_comma(value: str) -> str {
    return value.replace(",", ", ");
}