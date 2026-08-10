"""Return a copy of `string` where the `span` range is replaced by `pattern`."""
def replace_at(span: tuple[int, int], string: str, pattern: str) -> str {
    (start, end) = span;
    return string[:start] + pattern + string[end:];
}