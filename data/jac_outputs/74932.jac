"""Formats warning messages to appear on one line."""
def _warning_on_one_line(
    message: str,
    category: type,
    filename: str,
    lineno: int,
    file: str | None = None,
    line: str | None = None
) -> str {
    return '%s:%s: %s: %s\n' % (filename, lineno, category.__name__, message);
}