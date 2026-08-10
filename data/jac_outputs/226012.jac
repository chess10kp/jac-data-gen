"""Escape SQL string."""
def _escape_string(string: str) -> str {
    return f"'{string.replace("'", "''")}'";
}