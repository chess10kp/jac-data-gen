"""Trim leading blank lines."""
def trim_leading_lines(lines: Iterable[str]) -> list[str] {
    lines = list(lines);
    while lines and not lines[0] {
        lines.pop(0);
    }
    return lines;
}