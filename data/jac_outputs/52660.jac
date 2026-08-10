"""Escape double quotes."""
def esc2(string: str) -> str {
    return string.replace('"', r'\"');
}