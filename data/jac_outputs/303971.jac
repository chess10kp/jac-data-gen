"""User warning formatter."""
def warning_on_one_line(
    message: str,
    category: type,
    filename: str,
    lineno: int,
    file: None = None,
    line: str | None = None
) -> str {
    return '{}:{}: {}: {}\n'.format(filename, lineno, category.__name__, message);
}