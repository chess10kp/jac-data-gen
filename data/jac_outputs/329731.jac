"""Create a union of multiple query expressions."""
def _union(queries: list[str]) -> str {
    return '(' + ' union '.join(queries) + ')';
}